import AppKit

final class SystemSettingsOpener {
    typealias OpenURL = (URL, @escaping (Bool) -> Void) -> Void

    private static let languageAndRegionURL = URL(
        string: "x-apple.systempreferences:com.apple.Localization-Settings.extension"
    )!
    private static let systemSettingsBundleIdentifier = "com.apple.systempreferences"

    private let openURL: OpenURL
    private let systemSettingsURL: () -> URL?
    private let openApplication: OpenURL

    init(
        openURL: @escaping OpenURL,
        systemSettingsURL: @escaping () -> URL?,
        openApplication: @escaping OpenURL
    ) {
        self.openURL = openURL
        self.systemSettingsURL = systemSettingsURL
        self.openApplication = openApplication
    }

    convenience init(workspace: NSWorkspace = .shared) {
        self.init(
            openURL: { url, completion in
                workspace.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                    completion(error == nil)
                }
            },
            systemSettingsURL: {
                workspace.urlForApplication(
                    withBundleIdentifier: SystemSettingsOpener.systemSettingsBundleIdentifier
                )
            },
            openApplication: { url, completion in
                workspace.openApplication(
                    at: url,
                    configuration: NSWorkspace.OpenConfiguration()
                ) { _, error in
                    completion(error == nil)
                }
            }
        )
    }

    func openLanguageAndRegion(completion: @escaping (Bool) -> Void) {
        openURL(Self.languageAndRegionURL) { [self] didOpenDeepLink in
            guard !didOpenDeepLink else {
                completion(true)
                return
            }
            guard let settingsURL = systemSettingsURL() else {
                completion(false)
                return
            }
            openApplication(settingsURL, completion)
        }
    }
}
