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
    public var lastNotifiedVersion: String?
    public var availableRelease: UpdateRelease?

    public init(
        lastCheckedAt: Date? = nil,
        lastNotifiedVersion: String? = nil,
        availableRelease: UpdateRelease? = nil
    ) {
        self.lastCheckedAt = lastCheckedAt
        self.lastNotifiedVersion = lastNotifiedVersion
        self.availableRelease = availableRelease
    }
}

public protocol UpdateCheckStateStore: AnyObject {
    func load() -> UpdateCheckState
    func save(_ state: UpdateCheckState)
}

public final class UpdateCheckCoordinator {
    private let store: any UpdateCheckStateStore
    private let currentVersion: String
    private var state: UpdateCheckState

    public private(set) var result: UpdateCheckResult?

    public init(store: any UpdateCheckStateStore, currentVersion: String) {
        self.store = store
        self.currentVersion = currentVersion
        var loadedState = store.load()
        if let release = loadedState.availableRelease,
           case let .updateAvailable(_, restoredRelease) = UpdateCheckPolicy.evaluate(
               currentVersion: currentVersion,
               release: release
           ) {
            state = loadedState
            result = .updateAvailable(
                currentVersion: currentVersion,
                release: restoredRelease
            )
        } else {
            let hadStoredRelease = loadedState.availableRelease != nil
            loadedState.availableRelease = nil
            state = loadedState
            result = nil
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
        self.result = result
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
            lastNotifiedVersion: state.lastNotifiedVersion
        )
        if shouldNotify, case let .updateAvailable(_, release) = result {
            state.lastNotifiedVersion = release.version
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
    case failed

    public var showsInstructions: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    public static func resolve(
        isChecking: Bool,
        result: UpdateCheckResult?
    ) -> Self {
        guard !isChecking else { return .checking }
        switch result {
        case .none:
            return .idle
        case let .upToDate(currentVersion):
            return .current(version: currentVersion)
        case let .updateAvailable(_, release):
            return .available(version: release.version)
        case .failed:
            return .failed
        }
    }
}

public enum UpdateCheckPolicy {
    public static func shouldNotify(
        _ result: UpdateCheckResult,
        trigger: UpdateCheckTrigger,
        lastNotifiedVersion: String?
    ) -> Bool {
        guard trigger == .automatic,
              case let .updateAvailable(_, release) = result else {
            return false
        }
        return release.version != lastNotifiedVersion
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
