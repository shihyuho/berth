struct UpdateSettingsContent {
    let title: String
    let automaticChecks: String
    let idle: String
    let checking: String
    let current: (String) -> String
    let available: (String) -> String
    let failed: String
    let check: String
    let viewInstructions: String

    static func localized() -> Self {
        Self(
            title: AppStrings.settingsUpdatesTitle,
            automaticChecks: AppStrings.settingsUpdatesAutomatic,
            idle: AppStrings.settingsUpdatesIdle,
            checking: AppStrings.settingsUpdatesChecking,
            current: AppStrings.settingsUpdatesCurrent,
            available: AppStrings.settingsUpdatesAvailable,
            failed: AppStrings.settingsUpdatesFailed,
            check: AppStrings.checkForUpdates,
            viewInstructions: AppStrings.viewUpdateInstructions
        )
    }
}
