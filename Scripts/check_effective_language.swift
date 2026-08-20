import Foundation

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("Effective Language check failed: \(message)\n".utf8))
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count >= 4 else {
    fail("usage: check_effective_language.swift <locale> <effective-language> <quit>")
}

let expectedLocalization = arguments[arguments.count - 3]
let expectedEffectiveLanguage = arguments[arguments.count - 2]
let expectedQuit = arguments[arguments.count - 1]
let appBundle = Bundle.main

guard appBundle.bundleURL.pathExtension == "app" else {
    fail("check must run as an App bundle executable")
}
guard appBundle.preferredLocalizations.first == expectedLocalization else {
    fail(
        "main bundle selected \(appBundle.preferredLocalizations.first ?? "none") "
            + "instead of \(expectedLocalization)"
    )
}

let effectiveLanguageName = AppLanguage.effectiveName(bundle: appBundle)
let content = AppLanguageSettingsContent.localized(
    effectiveLanguageName: effectiveLanguageName
)
guard content.effectiveLanguage == expectedEffectiveLanguage else {
    fail("displayed \(content.effectiveLanguage.debugDescription)")
}
guard AppStrings.quit == expectedQuit else {
    fail("UI lookup \(AppStrings.quit.debugDescription) disagreed with the Effective Language")
}

print(
    "Finished App main bundle selected \(expectedLocalization) and displayed "
        + content.effectiveLanguage.debugDescription
)
