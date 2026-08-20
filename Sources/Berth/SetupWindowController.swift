import AppKit
import BerthCore

final class SetupWindowController: NSWindowController, NSWindowDelegate {
    var onDisplaySelected: ((String) -> Void)?
    var onRequestAccessibility: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?
    var onOpenDesktopSettings: (() -> Void)?
    var onClose: (() -> Void)?

    private let displayPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let accessibilityStatus = NSTextField(wrappingLabelWithString: "")
    private let grantAccessibilityButton = NSButton()
    private let openAccessibilitySettingsButton = NSButton()
    private let setupStatus = NSTextField(wrappingLabelWithString: "")

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 570),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings.setupTitle
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        window.delegate = self
        buildContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        displays: [DisplayInfo],
        pinnedUUID: String?,
        isAccessibilityTrusted: Bool,
        state: SetupState
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
        } else {
            displayPopup.selectItem(at: 0)
        }
        displayPopup.isEnabled = !displays.isEmpty

        accessibilityStatus.stringValue = isAccessibilityTrusted
            ? AppStrings.setupAccessibilityGranted
            : AppStrings.setupAccessibilityRequired
        accessibilityStatus.textColor = isAccessibilityTrusted ? .systemGreen : .secondaryLabelColor
        grantAccessibilityButton.isHidden = isAccessibilityTrusted
        openAccessibilitySettingsButton.isHidden = isAccessibilityTrusted

        switch state.readiness {
        case .ready:
            setupStatus.stringValue = AppStrings.setupReady
            setupStatus.textColor = .systemGreen
        case .needsPinnedDisplay:
            setupStatus.stringValue = AppStrings.setupNeedsPinnedDisplay
            setupStatus.textColor = .secondaryLabelColor
        case .needsAccessibilityPermission:
            setupStatus.stringValue = AppStrings.setupNeedsAccessibility
            setupStatus.textColor = .secondaryLabelColor
        case .pinnedDisplayMissing:
            setupStatus.stringValue = AppStrings.setupPinnedDisplayMissing
            setupStatus.textColor = .systemOrange
        }
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 16
        root.translatesAutoresizingMaskIntoConstraints = false

        let heading = NSTextField(labelWithString: AppStrings.setupTitle)
        heading.font = .systemFont(ofSize: 24, weight: .semibold)
        root.addArrangedSubview(heading)

        let introduction = wrappingLabel(AppStrings.setupIntroduction)
        root.addArrangedSubview(introduction)

        let environmentButton = NSButton(
            title: AppStrings.setupOpenDesktopSettings,
            target: self,
            action: #selector(openDesktopSettings)
        )
        let environmentSection = section(
            title: AppStrings.setupEnvironmentTitle,
            body: AppStrings.setupEnvironmentBody,
            controls: [environmentButton]
        )
        root.addArrangedSubview(environmentSection)

        displayPopup.target = self
        displayPopup.action = #selector(displaySelectionChanged)
        displayPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        let displaySection = section(
            title: AppStrings.setupPinnedDisplayTitle,
            body: AppStrings.setupPinnedDisplayBody,
            controls: [displayPopup]
        )
        root.addArrangedSubview(displaySection)

        grantAccessibilityButton.title = AppStrings.setupGrantAccessibility
        grantAccessibilityButton.target = self
        grantAccessibilityButton.action = #selector(requestAccessibility)
        openAccessibilitySettingsButton.title = AppStrings.openAccessibilitySettings
        openAccessibilitySettingsButton.target = self
        openAccessibilitySettingsButton.action = #selector(openAccessibilitySettings)
        let accessibilityButtons = NSStackView(
            views: [grantAccessibilityButton, openAccessibilitySettingsButton]
        )
        accessibilityButtons.orientation = .horizontal
        accessibilityButtons.spacing = 8
        let accessibilitySection = section(
            title: AppStrings.setupAccessibilityTitle,
            body: AppStrings.setupAccessibilityBody,
            controls: [accessibilityStatus, accessibilityButtons]
        )
        root.addArrangedSubview(accessibilitySection)

        setupStatus.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        root.addArrangedSubview(setupStatus)

        let closeButton = NSButton(
            title: AppStrings.setupClose,
            target: self,
            action: #selector(closeWindow)
        )
        closeButton.keyEquivalent = "\r"
        root.addArrangedSubview(closeButton)

        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            root.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
            environmentSection.widthAnchor.constraint(equalTo: root.widthAnchor),
            displaySection.widthAnchor.constraint(equalTo: root.widthAnchor),
            accessibilitySection.widthAnchor.constraint(equalTo: root.widthAnchor),
            introduction.widthAnchor.constraint(equalTo: root.widthAnchor),
            setupStatus.widthAnchor.constraint(equalTo: root.widthAnchor),
        ])
    }

    private func section(title: String, body: String, controls: [NSView]) -> NSBox {
        let box = NSBox()
        box.title = title
        box.titlePosition = .atTop

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = wrappingLabel(body)
        stack.addArrangedSubview(bodyLabel)
        controls.forEach(stack.addArrangedSubview)

        guard let contentView = box.contentView else { return box }
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            bodyLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
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

    @objc private func requestAccessibility() {
        onRequestAccessibility?()
    }

    @objc private func openAccessibilitySettings() {
        onOpenAccessibilitySettings?()
    }

    @objc private func openDesktopSettings() {
        onOpenDesktopSettings?()
    }

    @objc private func closeWindow() {
        close()
    }
}
