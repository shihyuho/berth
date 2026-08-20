import Foundation

enum AppLanguage {
    static func effectiveName(bundle: Bundle = .main) -> String {
        let identifier = bundle.preferredLocalizations.first
            ?? bundle.developmentLocalization
            ?? "en"
        return displayName(for: identifier)
    }

    static func displayName(for identifier: String) -> String {
        let language = Locale.Language(identifier: identifier)
        let displayIdentifier = language.languageCode?.identifier == "zh"
            ? language.maximalIdentifier
            : identifier
        let languageLocale = Locale(identifier: displayIdentifier)
        return languageLocale.localizedString(forIdentifier: displayIdentifier) ?? identifier
    }
}

struct AppLanguageSettingsContent {
    let generalTitle: String
    let languageLabel: String
    let effectiveLanguage: String
    let instructions: String
    let openSettings: String
    let openError: String

    static func localized(effectiveLanguageName: String) -> Self {
        Self(
            generalTitle: AppStrings.settingsGeneralTitle,
            languageLabel: AppStrings.settingsAppLanguageLabel,
            effectiveLanguage: AppStrings.settingsEffectiveAppLanguage(
                effectiveLanguageName: effectiveLanguageName
            ),
            instructions: AppStrings.settingsAppLanguageInstructions,
            openSettings: AppStrings.settingsOpenLanguageAndRegion,
            openError: AppStrings.settingsOpenLanguageAndRegionError
        )
    }
}
