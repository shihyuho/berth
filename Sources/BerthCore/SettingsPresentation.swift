public struct SettingsPresentation: Equatable, Sendable {
    public enum AccessibilityStatus: Equatable, Sendable {
        case granted
        case needsInitialGrant
        case needsRecovery
    }

    public enum AccessibilityAction: Equatable, Sendable {
        case none
        case requestPermission
        case openSystemSettings
    }

    public enum LaunchAtLoginStatus: Equatable, Sendable {
        case enabled
        case disabled
        case requiresApproval
        case unavailable
    }

    public enum LaunchAtLoginAction: Equatable, Sendable {
        case enable
        case disable
        case openSystemSettings
        case none
    }

    public let setupState: SetupState
    public let accessibilityStatus: AccessibilityStatus
    public let accessibilityAction: AccessibilityAction
    public let launchAtLoginStatus: LaunchAtLoginStatus
    public let launchAtLoginAction: LaunchAtLoginAction

    public static func resolve(
        setupSnapshot: SetupSnapshot,
        launchAtLoginStatus: LaunchAtLoginStatus
    ) -> SettingsPresentation {
        let accessibilityStatus: AccessibilityStatus
        let accessibilityAction: AccessibilityAction
        if setupSnapshot.isAccessibilityTrusted {
            accessibilityStatus = .granted
            accessibilityAction = .none
        } else if setupSnapshot.hasCompletedSetup {
            accessibilityStatus = .needsRecovery
            accessibilityAction = .openSystemSettings
        } else {
            accessibilityStatus = .needsInitialGrant
            accessibilityAction = .requestPermission
        }

        let launchAtLoginAction: LaunchAtLoginAction
        switch launchAtLoginStatus {
        case .enabled:
            launchAtLoginAction = .disable
        case .disabled:
            launchAtLoginAction = .enable
        case .requiresApproval:
            launchAtLoginAction = .openSystemSettings
        case .unavailable:
            launchAtLoginAction = .none
        }

        return SettingsPresentation(
            setupState: SetupState.resolve(setupSnapshot),
            accessibilityStatus: accessibilityStatus,
            accessibilityAction: accessibilityAction,
            launchAtLoginStatus: launchAtLoginStatus,
            launchAtLoginAction: launchAtLoginAction
        )
    }
}
