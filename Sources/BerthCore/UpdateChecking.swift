import Foundation

public struct UpdateRelease: Codable, Equatable, Sendable {
    public let version: String
    public let detailsURL: URL

    public init(version: String, detailsURL: URL) {
        self.version = version
        self.detailsURL = detailsURL
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case upToDate(currentVersion: String)
    case updateAvailable(currentVersion: String, release: UpdateRelease)
    case failed
}

public enum UpdateCheckTrigger: Equatable, Sendable {
    case automatic
    case manual
}

public struct UpdateCheckState: Codable, Equatable, Sendable {
    public var lastCheckedAt: Date?
    public var notifiedVersions: Set<String>
    public var availableRelease: UpdateRelease?

    public init(
        lastCheckedAt: Date? = nil,
        notifiedVersions: Set<String> = [],
        availableRelease: UpdateRelease? = nil
    ) {
        self.lastCheckedAt = lastCheckedAt
        self.notifiedVersions = notifiedVersions
        self.availableRelease = availableRelease
    }

    private enum CodingKeys: String, CodingKey {
        case lastCheckedAt
        case notifiedVersions
        case availableRelease
        case lastNotifiedVersion
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastCheckedAt = try container.decodeIfPresent(Date.self, forKey: .lastCheckedAt)
        availableRelease = try container.decodeIfPresent(
            UpdateRelease.self,
            forKey: .availableRelease
        )
        if let versions = try container.decodeIfPresent(
            Set<String>.self,
            forKey: .notifiedVersions
        ) {
            notifiedVersions = versions
        } else if let legacyVersion = try container.decodeIfPresent(
            String.self,
            forKey: .lastNotifiedVersion
        ) {
            notifiedVersions = [legacyVersion]
        } else {
            notifiedVersions = []
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(lastCheckedAt, forKey: .lastCheckedAt)
        try container.encode(notifiedVersions, forKey: .notifiedVersions)
        try container.encodeIfPresent(availableRelease, forKey: .availableRelease)
    }
}

public protocol UpdateCheckStateStore: AnyObject {
    func load() -> UpdateCheckState
    func save(_ state: UpdateCheckState)
}

public final class UpdateCheckCoordinator {
    private let store: any UpdateCheckStateStore
    private var state: UpdateCheckState

    public private(set) var lastAttemptResult: UpdateCheckResult?

    public var knownAvailableRelease: UpdateRelease? {
        state.availableRelease
    }

    public init(store: any UpdateCheckStateStore, currentVersion: String) {
        self.store = store
        var loadedState = store.load()
        if let release = loadedState.availableRelease,
           case .updateAvailable = UpdateCheckPolicy.evaluate(
               currentVersion: currentVersion,
               release: release
           ) {
            state = loadedState
            lastAttemptResult = nil
        } else {
            let hadStoredRelease = loadedState.availableRelease != nil
            loadedState.availableRelease = nil
            state = loadedState
            lastAttemptResult = nil
            if hadStoredRelease {
                store.save(loadedState)
            }
        }
    }

    public func beginCheck(
        trigger: UpdateCheckTrigger,
        automaticChecksEnabled: Bool,
        now: Date
    ) -> Bool {
        guard UpdateCheckPolicy.shouldCheck(
            trigger: trigger,
            automaticChecksEnabled: automaticChecksEnabled,
            lastCheckedAt: state.lastCheckedAt,
            now: now
        ) else {
            return false
        }
        state.lastCheckedAt = now
        store.save(state)
        return true
    }

    @discardableResult
    public func completeCheck(
        _ result: UpdateCheckResult,
        trigger: UpdateCheckTrigger
    ) -> Bool {
        lastAttemptResult = result
        switch result {
        case .upToDate:
            state.availableRelease = nil
        case let .updateAvailable(_, release):
            state.availableRelease = release
        case .failed:
            break
        }

        let shouldNotify = UpdateCheckPolicy.shouldNotify(
            result,
            trigger: trigger,
            notifiedVersions: state.notifiedVersions
        )
        if shouldNotify, case let .updateAvailable(_, release) = result {
            state.notifiedVersions.insert(release.version)
        }
        store.save(state)
        return shouldNotify
    }
}

public enum UpdateCheckPresentation: Equatable, Sendable {
    case idle
    case checking
    case current(version: String)
    case available(version: String)
    case failed(knownAvailableVersion: String?)

    public var showsInstructions: Bool {
        switch self {
        case .available:
            return true
        case let .failed(knownAvailableVersion):
            return knownAvailableVersion != nil
        case .idle, .checking, .current:
            return false
        }
    }

    public static func resolve(
        isChecking: Bool,
        result: UpdateCheckResult?,
        knownAvailableRelease: UpdateRelease? = nil
    ) -> Self {
        guard !isChecking else { return .checking }
        switch result {
        case .none:
            if let knownAvailableRelease {
                return .available(version: knownAvailableRelease.version)
            }
            return .idle
        case let .upToDate(currentVersion):
            return .current(version: currentVersion)
        case let .updateAvailable(_, release):
            return .available(version: release.version)
        case .failed:
            return .failed(knownAvailableVersion: knownAvailableRelease?.version)
        }
    }
}

public enum UpdateCheckAlert: Equatable, Sendable {
    case none
    case upToDate(version: String)
    case updateAvailable(release: UpdateRelease)

    public static func resolve(
        result: UpdateCheckResult,
        trigger: UpdateCheckTrigger,
        shouldNotifyAboutAvailableUpdate: Bool
    ) -> Self {
        if trigger == .manual,
           case let .upToDate(currentVersion) = result {
            return .upToDate(version: currentVersion)
        }
        if shouldNotifyAboutAvailableUpdate,
           case let .updateAvailable(_, release) = result {
            return .updateAvailable(release: release)
        }
        return .none
    }
}

public enum UpdateCheckPolicy {
    public static func shouldNotify(
        _ result: UpdateCheckResult,
        trigger: UpdateCheckTrigger,
        notifiedVersions: Set<String>
    ) -> Bool {
        guard trigger == .automatic,
              case let .updateAvailable(_, release) = result else {
            return false
        }
        return !notifiedVersions.contains(release.version)
    }

    public static func shouldCheck(
        trigger: UpdateCheckTrigger,
        automaticChecksEnabled: Bool,
        lastCheckedAt: Date?,
        now: Date
    ) -> Bool {
        if trigger == .manual {
            return true
        }
        guard automaticChecksEnabled else { return false }
        guard let lastCheckedAt else { return true }
        return now.timeIntervalSince(lastCheckedAt) >= 24 * 60 * 60
    }

    public static func evaluate(
        currentVersion: String,
        release: UpdateRelease
    ) -> UpdateCheckResult {
        guard let current = SemanticVersion(currentVersion),
              let latest = SemanticVersion(release.version) else {
            return .failed
        }
        if latest <= current {
            return .upToDate(currentVersion: currentVersion)
        }
        return .updateAvailable(currentVersion: currentVersion, release: release)
    }
}

private struct SemanticVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    init?(_ value: String) {
        let components = value.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]),
              major >= 0,
              minor >= 0,
              patch >= 0 else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
