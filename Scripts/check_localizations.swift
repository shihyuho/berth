#!/usr/bin/env swift

import Foundation

private let requiredKeys: Set<String> = [
    "menu.pinDockTo",
    "menu.mainDisplaySuffix",
    "menu.unpin",
    "menu.bringDockBack",
    "menu.openAccessibilitySettings",
    "menu.launchAtLogin",
    "menu.quit",
    "status.unpinned",
    "status.waitingForAccessibility",
    "status.pinnedDisplayMissing",
    "status.pinned",
    "status.dockControlInactive",
    "display.fallbackName",
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
        "menu.launchAtLogin": "Launch at Login",
        "menu.quit": "Quit",
        "status.unpinned": "Status: Not pinned",
        "status.waitingForAccessibility": "Status: Waiting for Accessibility permission; Dock control is paused",
        "status.pinnedDisplayMissing": "Status: Pinned display not found; choose another display",
        "status.pinned": "Status: Pinned to “%@”",
        "status.dockControlInactive": "Status: Dock control is inactive",
        "display.fallbackName": "Display %u",
    ],
    "zh-TW": [
        "menu.pinDockTo": "將 Dock 固定於：",
        "menu.mainDisplaySuffix": "（主螢幕）",
        "menu.unpin": "取消固定",
        "menu.bringDockBack": "立即將 Dock 帶回固定螢幕",
        "menu.openAccessibilitySettings": "開啟「輔助使用」設定…",
        "menu.launchAtLogin": "登入時自動啟動",
        "menu.quit": "結束",
        "status.unpinned": "狀態：未固定",
        "status.waitingForAccessibility": "狀態：正在等待「輔助使用」權限；Dock 控制已暫停",
        "status.pinnedDisplayMissing": "狀態：找不到固定螢幕；請重新選擇",
        "status.pinned": "狀態：已固定於「%@」",
        "status.dockControlInactive": "狀態：Dock 控制未啟動",
        "display.fallbackName": "螢幕 %u",
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
