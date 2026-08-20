import Foundation

enum AppStrings {
    private enum Key: String {
        case menuPinDockTo = "menu.pinDockTo"
        case menuMainDisplaySuffix = "menu.mainDisplaySuffix"
        case menuUnpin = "menu.unpin"
        case menuBringDockBack = "menu.bringDockBack"
        case menuOpenAccessibilitySettings = "menu.openAccessibilitySettings"
        case menuContinueSetup = "menu.continueSetup"
        case menuSettings = "menu.settings"
        case menuLaunchAtLogin = "menu.launchAtLogin"
        case menuQuit = "menu.quit"
        case statusUnpinned = "status.unpinned"
        case statusWaitingForAccessibility = "status.waitingForAccessibility"
        case statusPinnedDisplayMissing = "status.pinnedDisplayMissing"
        case statusPinned = "status.pinned"
        case statusDockControlInactive = "status.dockControlInactive"
        case displayFallbackName = "display.fallbackName"
        case setupTitle = "setup.title"
        case setupIntroduction = "setup.introduction"
        case setupEnvironmentTitle = "setup.environment.title"
        case setupEnvironmentBody = "setup.environment.body"
        case setupOpenDesktopSettings = "setup.environment.openSettings"
        case setupPinnedDisplayTitle = "setup.pinnedDisplay.title"
        case setupPinnedDisplayBody = "setup.pinnedDisplay.body"
        case setupChooseDisplay = "setup.pinnedDisplay.choose"
        case setupAccessibilityTitle = "setup.accessibility.title"
        case setupAccessibilityBody = "setup.accessibility.body"
        case setupGrantAccessibility = "setup.accessibility.grant"
        case setupAccessibilityGranted = "setup.accessibility.granted"
        case setupAccessibilityRequired = "setup.accessibility.required"
        case setupReady = "setup.status.ready"
        case setupNeedsPinnedDisplay = "setup.status.needsPinnedDisplay"
        case setupNeedsAccessibility = "setup.status.needsAccessibility"
        case setupPinnedDisplayMissing = "setup.status.pinnedDisplayMissing"
        case setupClose = "setup.close"
        case settingsTitle = "settings.title"
        case settingsPinnedDisplayMissing = "settings.pinnedDisplay.missing"
        case settingsPinnedDisplayUnavailableSelection = "settings.pinnedDisplay.unavailableSelection"
        case settingsAccessibilityRecovery = "settings.accessibility.recovery"
        case settingsLaunchAtLoginTitle = "settings.launchAtLogin.title"
        case settingsLaunchAtLoginEnabled = "settings.launchAtLogin.enabled"
        case settingsLaunchAtLoginDisabled = "settings.launchAtLogin.disabled"
        case settingsLaunchAtLoginRequiresApproval = "settings.launchAtLogin.requiresApproval"
        case settingsLaunchAtLoginUnavailable = "settings.launchAtLogin.unavailable"
        case settingsOpenLoginItemsSettings = "settings.launchAtLogin.openSettings"
        case settingsAboutTitle = "settings.about.title"
        case settingsVersion = "settings.about.version"
        case settingsProjectDescription = "settings.about.projectDescription"
        case settingsOpenProject = "settings.about.openProject"
    }

    static var pinDockTo: String { localized(.menuPinDockTo) }
    static var mainDisplaySuffix: String { localized(.menuMainDisplaySuffix) }
    static var unpin: String { localized(.menuUnpin) }
    static var bringDockBack: String { localized(.menuBringDockBack) }
    static var openAccessibilitySettings: String { localized(.menuOpenAccessibilitySettings) }
    static var continueSetup: String { localized(.menuContinueSetup) }
    static var settings: String { localized(.menuSettings) }
    static var launchAtLogin: String { localized(.menuLaunchAtLogin) }
    static var quit: String { localized(.menuQuit) }
    static var unpinnedStatus: String { localized(.statusUnpinned) }
    static var waitingForAccessibilityStatus: String { localized(.statusWaitingForAccessibility) }
    static var pinnedDisplayMissingStatus: String { localized(.statusPinnedDisplayMissing) }
    static var dockControlInactiveStatus: String { localized(.statusDockControlInactive) }
    static var setupTitle: String { localized(.setupTitle) }
    static var setupIntroduction: String { localized(.setupIntroduction) }
    static var setupEnvironmentTitle: String { localized(.setupEnvironmentTitle) }
    static var setupEnvironmentBody: String { localized(.setupEnvironmentBody) }
    static var setupOpenDesktopSettings: String { localized(.setupOpenDesktopSettings) }
    static var setupPinnedDisplayTitle: String { localized(.setupPinnedDisplayTitle) }
    static var setupPinnedDisplayBody: String { localized(.setupPinnedDisplayBody) }
    static var setupChooseDisplay: String { localized(.setupChooseDisplay) }
    static var setupAccessibilityTitle: String { localized(.setupAccessibilityTitle) }
    static var setupAccessibilityBody: String { localized(.setupAccessibilityBody) }
    static var setupGrantAccessibility: String { localized(.setupGrantAccessibility) }
    static var setupAccessibilityGranted: String { localized(.setupAccessibilityGranted) }
    static var setupAccessibilityRequired: String { localized(.setupAccessibilityRequired) }
    static var setupReady: String { localized(.setupReady) }
    static var setupNeedsPinnedDisplay: String { localized(.setupNeedsPinnedDisplay) }
    static var setupNeedsAccessibility: String { localized(.setupNeedsAccessibility) }
    static var setupPinnedDisplayMissing: String { localized(.setupPinnedDisplayMissing) }
    static var setupClose: String { localized(.setupClose) }
    static var settingsTitle: String { localized(.settingsTitle) }
    static var settingsPinnedDisplayMissing: String { localized(.settingsPinnedDisplayMissing) }
    static var settingsPinnedDisplayUnavailableSelection: String {
        localized(.settingsPinnedDisplayUnavailableSelection)
    }
    static var settingsAccessibilityRecovery: String { localized(.settingsAccessibilityRecovery) }
    static var settingsLaunchAtLoginTitle: String { localized(.settingsLaunchAtLoginTitle) }
    static var settingsLaunchAtLoginEnabled: String { localized(.settingsLaunchAtLoginEnabled) }
    static var settingsLaunchAtLoginDisabled: String { localized(.settingsLaunchAtLoginDisabled) }
    static var settingsLaunchAtLoginRequiresApproval: String {
        localized(.settingsLaunchAtLoginRequiresApproval)
    }
    static var settingsLaunchAtLoginUnavailable: String { localized(.settingsLaunchAtLoginUnavailable) }
    static var settingsOpenLoginItemsSettings: String { localized(.settingsOpenLoginItemsSettings) }
    static var settingsAboutTitle: String { localized(.settingsAboutTitle) }
    static var settingsProjectDescription: String { localized(.settingsProjectDescription) }
    static var settingsOpenProject: String { localized(.settingsOpenProject) }

    static func pinnedStatus(displayName: String) -> String {
        String(
            format: localized(.statusPinned),
            locale: Locale.current,
            arguments: [displayName]
        )
    }

    static func fallbackDisplayName(displayID: UInt32) -> String {
        String(
            format: localized(.displayFallbackName),
            locale: Locale.current,
            arguments: [displayID]
        )
    }

    static func settingsVersion(version: String) -> String {
        String(
            format: localized(.settingsVersion),
            locale: Locale.current,
            arguments: [version]
        )
    }

    private static func localized(_ key: Key) -> String {
        Bundle.main.localizedString(forKey: key.rawValue, value: nil, table: "Localizable")
    }
}
