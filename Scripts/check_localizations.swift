#!/usr/bin/env swift

import Foundation

private let requiredKeys: Set<String> = [
    "menu.pinDockTo",
    "menu.mainDisplaySuffix",
    "menu.unpin",
    "menu.bringDockBack",
    "menu.openAccessibilitySettings",
    "menu.continueSetup",
    "menu.settings",
    "menu.launchAtLogin",
    "menu.quit",
    "status.unpinned",
    "status.waitingForAccessibility",
    "status.pinnedDisplayMissing",
    "status.pinned",
    "status.dockControlInactive",
    "display.fallbackName",
    "setup.title",
    "setup.introduction",
    "setup.environment.title",
    "setup.environment.body",
    "setup.environment.openSettings",
    "setup.pinnedDisplay.title",
    "setup.pinnedDisplay.body",
    "setup.pinnedDisplay.choose",
    "setup.accessibility.title",
    "setup.accessibility.body",
    "setup.accessibility.grant",
    "setup.accessibility.granted",
    "setup.accessibility.required",
    "setup.status.ready",
    "setup.status.needsPinnedDisplay",
    "setup.status.needsAccessibility",
    "setup.status.pinnedDisplayMissing",
    "setup.close",
    "settings.title",
    "settings.pinnedDisplay.missing",
    "settings.pinnedDisplay.unavailableSelection",
    "settings.accessibility.recovery",
    "settings.general.title",
    "settings.appLanguage.label",
    "settings.appLanguage.effective",
    "settings.appLanguage.instructions",
    "settings.appLanguage.openSettings",
    "settings.appLanguage.openError",
    "settings.launchAtLogin.title",
    "settings.launchAtLogin.enabled",
    "settings.launchAtLogin.disabled",
    "settings.launchAtLogin.requiresApproval",
    "settings.launchAtLogin.unavailable",
    "settings.launchAtLogin.openSettings",
    "settings.about.title",
    "settings.about.version",
    "settings.about.projectDescription",
    "settings.about.openProject",
]

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("Localization check failed: \(message)\n".utf8))
    exit(1)
}

private func checkCatalog(at path: String) {
    let catalogURL = URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: catalogURL) else {
        fail("cannot read catalog at \(catalogURL.path)")
    }
    guard
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let sourceLanguage = root["sourceLanguage"] as? String,
        let strings = root["strings"] as? [String: Any]
    else {
        fail("catalog is not valid String Catalog JSON")
    }

    guard sourceLanguage == "en" else {
        fail("sourceLanguage must be en, found \(sourceLanguage)")
    }

    let actualKeys = Set(strings.keys)
    let missingKeys = requiredKeys.subtracting(actualKeys).sorted()
    guard missingKeys.isEmpty else {
        fail("missing semantic keys: \(missingKeys.joined(separator: ", "))")
    }

    var declaredLocales = Set<String>()
    for value in strings.values {
        guard
            let entry = value as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any]
        else { continue }
        declaredLocales.formUnion(localizations.keys)
    }

    guard declaredLocales.isSuperset(of: ["en", "zh-TW"]) else {
        fail("catalog must declare complete en and zh-TW localizations")
    }

    for key in actualKeys.sorted() {
        guard
            let entry = strings[key] as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any]
        else {
            fail("\(key) has no localizations")
        }

        for locale in declaredLocales.sorted() {
            guard
                let localization = localizations[locale] as? [String: Any],
                let stringUnit = localization["stringUnit"] as? [String: Any],
                let state = stringUnit["state"] as? String,
                let value = stringUnit["value"] as? String,
                state == "translated",
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                fail("\(key) has no complete, non-empty \(locale) translation")
            }
        }
    }

    print("Localization catalog is complete for: \(declaredLocales.sorted().joined(separator: ", "))")
}

private let expectedValues: [String: [String: String]] = [
    "en": [
        "menu.pinDockTo": "Pin Dock to:",
        "menu.mainDisplaySuffix": " (Main Display)",
        "menu.unpin": "Unpin",
        "menu.bringDockBack": "Bring Dock Back to Pinned Display",
        "menu.openAccessibilitySettings": "Open Accessibility Settings…",
        "menu.continueSetup": "Continue Setup…",
        "menu.settings": "Settings…",
        "menu.launchAtLogin": "Launch at Login",
        "menu.quit": "Quit",
        "status.unpinned": "Status: Not pinned",
        "status.waitingForAccessibility": "Status: Waiting for Accessibility permission; Dock control is paused",
        "status.pinnedDisplayMissing": "Status: Pinned display not found; choose another display",
        "status.pinned": "Status: Pinned to “%@”",
        "status.dockControlInactive": "Status: Dock control is inactive",
        "display.fallbackName": "Display %u",
        "setup.title": "Set Up Berth",
        "setup.introduction": "Complete these steps in one place. You can close this window and continue later from the Berth menu.",
        "setup.environment.title": "Display Spaces",
        "setup.environment.body": "Berth requires “Displays have separate Spaces” to be enabled. Check it in Desktop & Dock settings; macOS does not provide a reliable way to verify it automatically.",
        "setup.environment.openSettings": "Open Desktop & Dock Settings…",
        "setup.pinnedDisplay.title": "Pinned Display",
        "setup.pinnedDisplay.body": "Choose the display where the Dock should remain.",
        "setup.pinnedDisplay.choose": "Choose a display…",
        "setup.accessibility.title": "Accessibility Permission",
        "setup.accessibility.body": "Berth needs Accessibility permission to keep the Dock on the Pinned Display.",
        "setup.accessibility.grant": "Grant Accessibility Permission",
        "setup.accessibility.granted": "Accessibility permission is granted.",
        "setup.accessibility.required": "Accessibility permission is required.",
        "setup.status.ready": "Setup complete. Dock Control is ready.",
        "setup.status.needsPinnedDisplay": "Choose a Pinned Display to continue.",
        "setup.status.needsAccessibility": "Grant Accessibility permission to continue.",
        "setup.status.pinnedDisplayMissing": "The Pinned Display is unavailable. Connect it or choose another display.",
        "setup.close": "Close",
        "settings.title": "Berth Settings",
        "settings.pinnedDisplay.missing": "The Pinned Display is unavailable. Connect it or choose another display.",
        "settings.pinnedDisplay.unavailableSelection": "Pinned Display (Unavailable)",
        "settings.accessibility.recovery": "Accessibility permission was revoked. Open System Settings to restore Dock Control.",
        "settings.general.title": "General",
        "settings.appLanguage.label": "App Language",
        "settings.appLanguage.effective": "Currently using: %@",
        "settings.appLanguage.instructions": "In Language & Region, add or select Berth under Applications, choose a language, then reopen Berth.",
        "settings.appLanguage.openSettings": "Open Language & Region…",
        "settings.appLanguage.openError": "Couldn’t open System Settings. Open System Settings → General → Language & Region → Applications.",
        "settings.launchAtLogin.title": "Launch at Login",
        "settings.launchAtLogin.enabled": "Berth is registered to launch at login.",
        "settings.launchAtLogin.disabled": "Berth will not launch at login.",
        "settings.launchAtLogin.requiresApproval": "Approval is required in System Settings.",
        "settings.launchAtLogin.unavailable": "Launch at Login is available in the packaged app.",
        "settings.launchAtLogin.openSettings": "Open Login Items Settings…",
        "settings.about.title": "About",
        "settings.about.version": "Berth %@",
        "settings.about.projectDescription": "Berth keeps the macOS Dock on the display you choose as its persistent berth.",
        "settings.about.openProject": "View Project on GitHub",
    ],
    "zh-TW": [
        "menu.pinDockTo": "將 Dock 固定於：",
        "menu.mainDisplaySuffix": "（主螢幕）",
        "menu.unpin": "取消固定",
        "menu.bringDockBack": "立即將 Dock 帶回固定螢幕",
        "menu.openAccessibilitySettings": "開啟「輔助使用」設定…",
        "menu.continueSetup": "繼續設定…",
        "menu.settings": "設定…",
        "menu.launchAtLogin": "登入時自動啟動",
        "menu.quit": "結束",
        "status.unpinned": "狀態：未固定",
        "status.waitingForAccessibility": "狀態：正在等待「輔助使用」權限；Dock 控制已暫停",
        "status.pinnedDisplayMissing": "狀態：找不到固定螢幕；請重新選擇",
        "status.pinned": "狀態：已固定於「%@」",
        "status.dockControlInactive": "狀態：Dock 控制未啟動",
        "display.fallbackName": "螢幕 %u",
        "setup.title": "設定 Berth",
        "setup.introduction": "請在此完成設定。你可以關閉視窗，稍後再從 Berth 選單繼續。",
        "setup.environment.title": "顯示器空間",
        "setup.environment.body": "Berth 需要開啟「顯示器具有獨立的空間」。請在「桌面與 Dock」設定中確認；macOS 沒有可靠的自動檢查方式。",
        "setup.environment.openSettings": "開啟「桌面與 Dock」設定…",
        "setup.pinnedDisplay.title": "固定螢幕",
        "setup.pinnedDisplay.body": "選擇 Dock 應保持所在的固定螢幕。",
        "setup.pinnedDisplay.choose": "選擇螢幕…",
        "setup.accessibility.title": "輔助使用權限",
        "setup.accessibility.body": "Berth 需要「輔助使用」權限，才能將 Dock 保持在固定螢幕上。",
        "setup.accessibility.grant": "授予「輔助使用」權限",
        "setup.accessibility.granted": "已授予「輔助使用」權限。",
        "setup.accessibility.required": "尚未授予「輔助使用」權限。",
        "setup.status.ready": "設定完成。Dock 控制已就緒。",
        "setup.status.needsPinnedDisplay": "請選擇固定螢幕以繼續。",
        "setup.status.needsAccessibility": "請授予「輔助使用」權限以繼續。",
        "setup.status.pinnedDisplayMissing": "固定螢幕目前無法使用。請連接該螢幕或選擇其他螢幕。",
        "setup.close": "關閉",
        "settings.title": "Berth 設定",
        "settings.pinnedDisplay.missing": "固定螢幕目前無法使用。請連接該螢幕或選擇其他螢幕。",
        "settings.pinnedDisplay.unavailableSelection": "固定螢幕（目前無法使用）",
        "settings.accessibility.recovery": "「輔助使用」權限已被撤銷。請開啟「系統設定」以恢復 Dock 控制。",
        "settings.general.title": "一般",
        "settings.appLanguage.label": "App 語言",
        "settings.appLanguage.effective": "目前使用：%@",
        "settings.appLanguage.instructions": "請在「語言與地區」的「應用程式」區塊加入或選擇 Berth、選取語言，然後重新開啟 Berth。",
        "settings.appLanguage.openSettings": "開啟「語言與地區」…",
        "settings.appLanguage.openError": "無法開啟「系統設定」。請前往「系統設定」→「一般」→「語言與地區」→「應用程式」。",
        "settings.launchAtLogin.title": "登入時自動啟動",
        "settings.launchAtLogin.enabled": "Berth 已登錄為登入時自動啟動。",
        "settings.launchAtLogin.disabled": "Berth 不會在登入時自動啟動。",
        "settings.launchAtLogin.requiresApproval": "需要在「系統設定」中核准。",
        "settings.launchAtLogin.unavailable": "「登入時自動啟動」僅適用於已封裝的 App。",
        "settings.launchAtLogin.openSettings": "開啟「登入項目」設定…",
        "settings.about.title": "關於",
        "settings.about.version": "Berth %@",
        "settings.about.projectDescription": "Berth 會將 macOS Dock 保持在你選擇的固定螢幕上。",
        "settings.about.openProject": "在 GitHub 查看專案",
    ],
]

private func localizationBundle(for locale: String, in appBundle: Bundle) -> Bundle {
    guard
        let path = appBundle.path(forResource: locale, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else {
        fail("finished App bundle is missing \(locale).lproj")
    }
    return bundle
}

private func localized(_ key: String, locale: String, appBundle: Bundle) -> String {
    localizationBundle(for: locale, in: appBundle)
        .localizedString(forKey: key, value: nil, table: "Localizable")
}

private func checkBundle(at path: String) {
    guard let appBundle = Bundle(path: path) else {
        fail("cannot open App bundle at \(path)")
    }

    for locale in ["en", "zh-TW"] {
        guard let expected = expectedValues[locale] else { continue }
        for key in requiredKeys.sorted() {
            let actual = localized(key, locale: locale, appBundle: appBundle)
            guard actual == expected[key] else {
                fail("\(locale) lookup for \(key) returned \(actual.debugDescription)")
            }
        }
    }

    let available = appBundle.localizations.filter { $0 != "Base" }
    let unsupportedChoice = Bundle.preferredLocalizations(
        from: available,
        forPreferences: ["fr"]
    ).first
    guard unsupportedChoice == "en" else {
        fail("unsupported fr locale must resolve to en, resolved to \(unsupportedChoice ?? "none")")
    }
    let fallback = localized("menu.quit", locale: unsupportedChoice!, appBundle: appBundle)
    guard fallback == "Quit" else {
        fail("unsupported fr locale did not look up the English value")
    }

    let englishPinned = String(
        format: localized("status.pinned", locale: "en", appBundle: appBundle),
        locale: Locale(identifier: "en"),
        arguments: ["Studio Display"]
    )
    guard englishPinned == "Status: Pinned to “Studio Display”" else {
        fail("formatted English Pinned Display status is incorrect")
    }

    let englishVersion = String(
        format: localized("settings.about.version", locale: "en", appBundle: appBundle),
        locale: Locale(identifier: "en"),
        arguments: ["1.2.3"]
    )
    guard englishVersion == "Berth 1.2.3" else {
        fail("formatted English settings version is incorrect")
    }

    let chineseEffectiveLanguage = String(
        format: localized("settings.appLanguage.effective", locale: "zh-TW", appBundle: appBundle),
        locale: Locale(identifier: "zh-TW"),
        arguments: ["繁體中文（台灣）"]
    )
    guard chineseEffectiveLanguage == "目前使用：繁體中文（台灣）" else {
        fail("formatted zh-TW Effective Language is incorrect")
    }

    let chineseDisplay = String(
        format: localized("display.fallbackName", locale: "zh-TW", appBundle: appBundle),
        locale: Locale(identifier: "zh-TW"),
        arguments: [UInt32(42)]
    )
    guard chineseDisplay == "螢幕 42" else {
        fail("formatted zh-TW fallback display name is incorrect")
    }

    print("Finished App bundle localization lookups passed for en, zh-TW, and fr fallback")
}

private func checkMainBundleFallback() {
    let appBundle = Bundle.main
    guard appBundle.bundleURL.pathExtension == "app" else {
        fail("main-bundle check must run as an App bundle executable")
    }
    guard Locale.preferredLanguages.first?.hasPrefix("fr") == true else {
        fail("main-bundle check must run with French as the preferred language")
    }
    guard appBundle.preferredLocalizations.first == "en" else {
        fail("finished App main bundle did not select en for unsupported fr")
    }

    let fallback = appBundle.localizedString(
        forKey: "menu.quit",
        value: nil,
        table: "Localizable"
    )
    guard fallback == "Quit" else {
        fail("finished App main-bundle lookup did not fall back from fr to English")
    }

    print("Finished App main-bundle lookup fell back from fr to English")
}

if CommandLine.arguments.contains("--main-bundle-fallback") {
    checkMainBundleFallback()
    exit(0)
}

guard CommandLine.arguments.count == 3 else {
    fail("usage: check_localizations.swift <catalog|bundle> <path> | --main-bundle-fallback")
}

switch CommandLine.arguments[1] {
case "catalog":
    checkCatalog(at: CommandLine.arguments[2])
case "bundle":
    checkBundle(at: CommandLine.arguments[2])
default:
    fail("unknown check: \(CommandLine.arguments[1])")
}
