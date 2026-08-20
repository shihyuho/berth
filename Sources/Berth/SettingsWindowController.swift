import AppKit
import BerthCore

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    var onDisplaySelected: ((String) -> Void)?
    var onRequestAccessibility: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?
    var onToggleLaunchAtLogin: (() -> Void)?
    var onOpenLoginItemsSettings: (() -> Void)?
    var onOpenProject: (() -> Void)?
    var onToggleAutomaticUpdateChecks: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?
    var onViewUpdateInstructions: (() -> Void)?
    var onClose: (() -> Void)?

    private let displayPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let displayStatus = NSTextField(wrappingLabelWithString: "")
    private let accessibilityStatus = NSTextField(wrappingLabelWithString: "")
    private let accessibilityButton = NSButton()
    private let launchAtLoginToggle = NSButton(checkboxWithTitle: AppStrings.launchAtLogin, target: nil, action: nil)
    private let launchAtLoginStatus = NSTextField(wrappingLabelWithString: "")
    private let openLoginItemsSettingsButton = NSButton()
    private let automaticUpdateChecksToggle = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let updateStatus = NSTextField(wrappingLabelWithString: "")
    private let checkForUpdatesButton = NSButton()
    private let viewUpdateInstructionsButton = NSButton()
    private let languageSettingsError: NSTextField
    private let systemSettingsOpener: SystemSettingsOpener
    private let updateContent: UpdateSettingsContent
    private var accessibilityAction: SettingsPresentation.AccessibilityAction = .none

    convenience init(version: String) {
        self.init(
            version: version,
            languageContent: .localized(effectiveLanguageName: AppLanguage.effectiveName()),
            systemSettingsOpener: SystemSettingsOpener(),
            updateContent: .localized()
        )
    }

    init(
        version: String,
        languageContent: AppLanguageSettingsContent,
        systemSettingsOpener: SystemSettingsOpener,
        updateContent: UpdateSettingsContent = .localized()
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 760),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        languageSettingsError = NSTextField(
            wrappingLabelWithString: languageContent.openError
        )
        self.systemSettingsOpener = systemSettingsOpener
        self.updateContent = updateContent
        window.title = AppStrings.settingsTitle
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        window.delegate = self
        buildContent(version: version, languageContent: languageContent)
        updateUpdates(automaticChecksEnabled: true, isChecking: false, result: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        displays: [DisplayInfo],
        pinnedUUID: String?,
        presentation: SettingsPresentation
    ) {
        updateDisplay(displays: displays, pinnedUUID: pinnedUUID, setupState: presentation.setupState)
        updateAccessibility(presentation)
        updateLaunchAtLogin(presentation)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func showLanguageSettingsError() {
        languageSettingsError.isHidden = false
    }

    func updateUpdates(
        automaticChecksEnabled: Bool,
        isChecking: Bool,
        result: UpdateCheckResult?
    ) {
        automaticUpdateChecksToggle.state = automaticChecksEnabled ? .on : .off
        checkForUpdatesButton.isEnabled = !isChecking
        let presentation = UpdateCheckPresentation.resolve(
            isChecking: isChecking,
            result: result
        )
        viewUpdateInstructionsButton.isHidden = !presentation.showsInstructions

        switch presentation {
        case .idle:
            updateStatus.stringValue = updateContent.idle
        case .checking:
            updateStatus.stringValue = updateContent.checking
        case let .current(version):
            updateStatus.stringValue = updateContent.current(version)
        case let .available(version):
            updateStatus.stringValue = updateContent.available(version)
        case .failed:
            updateStatus.stringValue = updateContent.failed
        }
        updateStatus.textColor = .secondaryLabelColor
    }

    private func updateDisplay(
        displays: [DisplayInfo],
        pinnedUUID: String?,
        setupState: SetupState
    ) {
        displayPopup.removeAllItems()
        displayPopup.addItem(withTitle: AppStrings.setupChooseDisplay)
        displayPopup.item(at: 0)?.isEnabled = false

        for display in displays {
            let title = display.isMain
                ? display.name + AppStrings.mainDisplaySuffix
                : display.name
            displayPopup.addItem(withTitle: title)
            displayPopup.lastItem?.representedObject = display.uuid
        }

        if let pinnedUUID,
           let index = displayPopup.itemArray.firstIndex(where: {
               $0.representedObject as? String == pinnedUUID
           }) {
            displayPopup.selectItem(at: index)
        } else if let pinnedUUID {
            displayPopup.addItem(withTitle: AppStrings.settingsPinnedDisplayUnavailableSelection)
            displayPopup.lastItem?.representedObject = pinnedUUID
            displayPopup.lastItem?.isEnabled = false
            displayPopup.select(displayPopup.lastItem)
        } else {
            displayPopup.selectItem(at: 0)
        }
        displayPopup.isEnabled = !displays.isEmpty

        if setupState.readiness == .pinnedDisplayMissing {
            displayStatus.stringValue = AppStrings.settingsPinnedDisplayMissing
            displayStatus.textColor = .systemOrange
            displayStatus.isHidden = false
        } else {
            displayStatus.isHidden = true
        }
    }

    private func updateAccessibility(_ presentation: SettingsPresentation) {
        accessibilityAction = presentation.accessibilityAction
        switch presentation.accessibilityStatus {
        case .granted:
            accessibilityStatus.stringValue = AppStrings.setupAccessibilityGranted
            accessibilityStatus.textColor = .systemGreen
            accessibilityButton.isHidden = true
        case .needsInitialGrant:
            accessibilityStatus.stringValue = AppStrings.setupAccessibilityRequired
            accessibilityStatus.textColor = .secondaryLabelColor
            accessibilityButton.title = AppStrings.setupGrantAccessibility
            accessibilityButton.isHidden = false
        case .needsRecovery:
            accessibilityStatus.stringValue = AppStrings.settingsAccessibilityRecovery
            accessibilityStatus.textColor = .systemOrange
            accessibilityButton.title = AppStrings.openAccessibilitySettings
            accessibilityButton.isHidden = false
        }
    }

    private func updateLaunchAtLogin(_ presentation: SettingsPresentation) {
        switch presentation.launchAtLoginStatus {
        case .enabled:
            launchAtLoginToggle.state = .on
            launchAtLoginStatus.stringValue = AppStrings.settingsLaunchAtLoginEnabled
        case .disabled:
            launchAtLoginToggle.state = .off
            launchAtLoginStatus.stringValue = AppStrings.settingsLaunchAtLoginDisabled
        case .requiresApproval:
            launchAtLoginToggle.state = .off
            launchAtLoginStatus.stringValue = AppStrings.settingsLaunchAtLoginRequiresApproval
        case .unavailable:
            launchAtLoginToggle.state = .off
            launchAtLoginStatus.stringValue = AppStrings.settingsLaunchAtLoginUnavailable
        }
        switch presentation.launchAtLoginAction {
        case .enable, .disable:
            launchAtLoginToggle.isEnabled = true
            openLoginItemsSettingsButton.isHidden = true
        case .openSystemSettings:
            launchAtLoginToggle.isEnabled = false
            openLoginItemsSettingsButton.isHidden = false
        case .none:
            launchAtLoginToggle.isEnabled = false
            openLoginItemsSettingsButton.isHidden = true
        }
        launchAtLoginStatus.textColor = .secondaryLabelColor
    }

    private func buildContent(
        version: String,
        languageContent: AppLanguageSettingsContent
    ) {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.translatesAutoresizingMaskIntoConstraints = false

        displayPopup.target = self
        displayPopup.action = #selector(displaySelectionChanged)
        displayPopup.widthAnchor.constraint(equalToConstant: 340).isActive = true
        let displaySection = section(
            title: AppStrings.setupPinnedDisplayTitle,
            controls: [displayPopup, displayStatus]
        )
        root.addArrangedSubview(displaySection)

        accessibilityButton.target = self
        accessibilityButton.action = #selector(performAccessibilityAction)
        let accessibilitySection = section(
            title: AppStrings.setupAccessibilityTitle,
            controls: [accessibilityStatus, accessibilityButton]
        )
        root.addArrangedSubview(accessibilitySection)

        launchAtLoginToggle.target = self
        launchAtLoginToggle.action = #selector(toggleLaunchAtLogin)
        openLoginItemsSettingsButton.title = AppStrings.settingsOpenLoginItemsSettings
        openLoginItemsSettingsButton.target = self
        openLoginItemsSettingsButton.action = #selector(openLoginItemsSettings)
        let languageLabel = NSTextField(labelWithString: languageContent.languageLabel)
        languageLabel.font = .systemFont(
            ofSize: NSFont.systemFontSize,
            weight: .semibold
        )
        let effectiveLanguage = wrappingLabel(languageContent.effectiveLanguage)
        effectiveLanguage.identifier = NSUserInterfaceItemIdentifier(
            "settings.appLanguage.effective"
        )
        let languageInstructions = wrappingLabel(languageContent.instructions)
        let openLanguageSettingsButton = NSButton(
            title: languageContent.openSettings,
            target: self,
            action: #selector(openLanguageSettings)
        )
        openLanguageSettingsButton.identifier = NSUserInterfaceItemIdentifier(
            "settings.appLanguage.openSettings"
        )
        languageSettingsError.identifier = NSUserInterfaceItemIdentifier(
            "settings.appLanguage.openError"
        )
        languageSettingsError.textColor = .systemRed
        languageSettingsError.isHidden = true
        let generalSection = section(
            title: languageContent.generalTitle,
            controls: [
                languageLabel,
                effectiveLanguage,
                languageInstructions,
                openLanguageSettingsButton,
                languageSettingsError,
                launchAtLoginToggle,
                launchAtLoginStatus,
                openLoginItemsSettingsButton,
            ]
        )
        root.addArrangedSubview(generalSection)

        automaticUpdateChecksToggle.identifier = NSUserInterfaceItemIdentifier(
            "settings.updates.automatic"
        )
        automaticUpdateChecksToggle.title = updateContent.automaticChecks
        automaticUpdateChecksToggle.target = self
        automaticUpdateChecksToggle.action = #selector(toggleAutomaticUpdateChecks)
        updateStatus.identifier = NSUserInterfaceItemIdentifier("settings.updates.status")
        checkForUpdatesButton.identifier = NSUserInterfaceItemIdentifier("settings.updates.check")
        checkForUpdatesButton.title = updateContent.check
        checkForUpdatesButton.target = self
        checkForUpdatesButton.action = #selector(checkForUpdates)
        viewUpdateInstructionsButton.identifier = NSUserInterfaceItemIdentifier(
            "settings.updates.view"
        )
        viewUpdateInstructionsButton.title = updateContent.viewInstructions
        viewUpdateInstructionsButton.target = self
        viewUpdateInstructionsButton.action = #selector(viewUpdateInstructions)
        viewUpdateInstructionsButton.isHidden = true
        let updateButtons = NSStackView(
            views: [checkForUpdatesButton, viewUpdateInstructionsButton]
        )
        updateButtons.orientation = .horizontal
        updateButtons.spacing = 8
        let updatesSection = section(
            title: updateContent.title,
            controls: [automaticUpdateChecksToggle, updateStatus, updateButtons]
        )
        root.addArrangedSubview(updatesSection)

        let versionLabel = NSTextField(labelWithString: AppStrings.settingsVersion(version: version))
        versionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        let projectDescription = wrappingLabel(AppStrings.settingsProjectDescription)
        let projectButton = NSButton(
            title: AppStrings.settingsOpenProject,
            target: self,
            action: #selector(openProject)
        )
        let aboutSection = section(
            title: AppStrings.settingsAboutTitle,
            controls: [versionLabel, projectDescription, projectButton]
        )
        root.addArrangedSubview(aboutSection)

        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            root.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            displaySection.widthAnchor.constraint(equalTo: root.widthAnchor),
            accessibilitySection.widthAnchor.constraint(equalTo: root.widthAnchor),
            generalSection.widthAnchor.constraint(equalTo: root.widthAnchor),
            updatesSection.widthAnchor.constraint(equalTo: root.widthAnchor),
            aboutSection.widthAnchor.constraint(equalTo: root.widthAnchor),
        ])
    }

    private func section(title: String, controls: [NSView]) -> NSBox {
        let box = NSBox()
        box.title = title
        box.titlePosition = .atTop

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        for control in controls {
            stack.addArrangedSubview(control)
            if let label = control as? NSTextField, label.cell?.wraps == true {
                label.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            }
        }

        guard let contentView = box.contentView else { return box }
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
        return box
    }

    private func wrappingLabel(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.maximumNumberOfLines = 0
        return label
    }

    @objc private func displaySelectionChanged() {
        guard let uuid = displayPopup.selectedItem?.representedObject as? String else { return }
        onDisplaySelected?(uuid)
    }

    @objc private func performAccessibilityAction() {
        switch accessibilityAction {
        case .requestPermission:
            onRequestAccessibility?()
        case .openSystemSettings:
            onOpenAccessibilitySettings?()
        case .none:
            break
        }
    }

    @objc private func toggleLaunchAtLogin() {
        onToggleLaunchAtLogin?()
    }

    @objc private func openLanguageSettings() {
        languageSettingsError.isHidden = true
        systemSettingsOpener.openLanguageAndRegion { [weak self] succeeded in
            guard !succeeded else { return }
            DispatchQueue.main.async {
                self?.showLanguageSettingsError()
            }
        }
    }

    @objc private func openLoginItemsSettings() {
        onOpenLoginItemsSettings?()
    }

    @objc private func openProject() {
        onOpenProject?()
    }

    @objc private func toggleAutomaticUpdateChecks() {
        onToggleAutomaticUpdateChecks?()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates?()
    }

    @objc private func viewUpdateInstructions() {
        onViewUpdateInstructions?()
    }
}
