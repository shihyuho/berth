import Foundation

enum AppStrings {
    private enum Key: String {
        case menuPinDockTo = "menu.pinDockTo"
        case menuMainDisplaySuffix = "menu.mainDisplaySuffix"
        case menuUnpin = "menu.unpin"
        case menuBringDockBack = "menu.bringDockBack"
        case menuOpenAccessibilitySettings = "menu.openAccessibilitySettings"
        case menuLaunchAtLogin = "menu.launchAtLogin"
        case menuQuit = "menu.quit"
        case statusUnpinned = "status.unpinned"
        case statusWaitingForAccessibility = "status.waitingForAccessibility"
        case statusPinnedDisplayMissing = "status.pinnedDisplayMissing"
        case statusPinned = "status.pinned"
        case statusDockControlInactive = "status.dockControlInactive"
        case displayFallbackName = "display.fallbackName"
    }

    static var pinDockTo: String { localized(.menuPinDockTo) }
    static var mainDisplaySuffix: String { localized(.menuMainDisplaySuffix) }
    static var unpin: String { localized(.menuUnpin) }
    static var bringDockBack: String { localized(.menuBringDockBack) }
    static var openAccessibilitySettings: String { localized(.menuOpenAccessibilitySettings) }
    static var launchAtLogin: String { localized(.menuLaunchAtLogin) }
    static var quit: String { localized(.menuQuit) }
    static var unpinnedStatus: String { localized(.statusUnpinned) }
    static var waitingForAccessibilityStatus: String { localized(.statusWaitingForAccessibility) }
    static var pinnedDisplayMissingStatus: String { localized(.statusPinnedDisplayMissing) }
    static var dockControlInactiveStatus: String { localized(.statusDockControlInactive) }

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

    private static func localized(_ key: Key) -> String {
        Bundle.main.localizedString(forKey: key.rawValue, value: nil, table: "Localizable")
    }
}
