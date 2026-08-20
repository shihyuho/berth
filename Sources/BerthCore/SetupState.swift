public struct SetupSnapshot: Equatable, Sendable {
    public let hasCompletedSetup: Bool
    public let hasPinnedDisplay: Bool
    public let isPinnedDisplayAvailable: Bool
    public let isAccessibilityTrusted: Bool

    public init(
        hasCompletedSetup: Bool,
        hasPinnedDisplay: Bool,
        isPinnedDisplayAvailable: Bool,
        isAccessibilityTrusted: Bool
    ) {
        self.hasCompletedSetup = hasCompletedSetup
        self.hasPinnedDisplay = hasPinnedDisplay
        self.isPinnedDisplayAvailable = isPinnedDisplayAvailable
        self.isAccessibilityTrusted = isAccessibilityTrusted
    }
}

public struct SetupState: Equatable, Sendable {
    public enum Readiness: Equatable, Sendable {
        case needsPinnedDisplay
        case needsAccessibilityPermission
        case ready
        case pinnedDisplayMissing
    }

    public let readiness: Readiness
    public let shouldPresentOnboarding: Bool
    public let shouldRecordCompletion: Bool
    public let isDockControlEligible: Bool

    public init(
        readiness: Readiness,
        shouldPresentOnboarding: Bool,
        shouldRecordCompletion: Bool,
        isDockControlEligible: Bool
    ) {
        self.readiness = readiness
        self.shouldPresentOnboarding = shouldPresentOnboarding
        self.shouldRecordCompletion = shouldRecordCompletion
        self.isDockControlEligible = isDockControlEligible
    }

    public static func resolve(_ snapshot: SetupSnapshot) -> SetupState {
        if snapshot.hasPinnedDisplay && !snapshot.isPinnedDisplayAvailable {
            return SetupState(
                readiness: .pinnedDisplayMissing,
                shouldPresentOnboarding: !snapshot.hasCompletedSetup,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        }
        if snapshot.hasPinnedDisplay && snapshot.isPinnedDisplayAvailable {
            if snapshot.isAccessibilityTrusted {
                return SetupState(
                    readiness: .ready,
                    shouldPresentOnboarding: false,
                    shouldRecordCompletion: !snapshot.hasCompletedSetup,
                    isDockControlEligible: true
                )
            }
            return SetupState(
                readiness: .needsAccessibilityPermission,
                shouldPresentOnboarding: !snapshot.hasCompletedSetup,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        }
        return SetupState(
            readiness: .needsPinnedDisplay,
            shouldPresentOnboarding: !snapshot.hasCompletedSetup,
            shouldRecordCompletion: false,
            isDockControlEligible: false
        )
    }
}
