import AppKit
import BerthCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let dockGuard = DockGuard()
    private var reconcileTimer: Timer?
    private var dockWatchTimer: Timer?
    private var setupRefreshTimer: Timer?
    private var settingsRefreshTimer: Timer?
    private var updateCheckTimer: Timer?
    private var setupWindowController: SetupWindowController?
    private var settingsWindowController: SettingsWindowController?
    private let latestReleaseClient = LatestReleaseClient()
    private var isCheckingForUpdates = false
    private lazy var updateCheckCoordinator = UpdateCheckCoordinator(
        store: UserDefaultsUpdateCheckStateStore(),
        currentVersion: currentVersion
    )

    private static let pinnedKey = "PinnedDisplayUUID"
    private static let setupCompletedKey = "HasCompletedSetup"
    private static let automaticUpdateChecksKey = "AutomaticUpdateChecksEnabled"
    private static let updateInstructionsURL = URL(
        string: "https://github.com/shihyuho/berth/blob/main/docs/getting-started.md#update-berth"
    )!

    private var pinnedUUID: String? {
        get { UserDefaults.standard.string(forKey: Self.pinnedKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: Self.pinnedKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.pinnedKey)
            }
        }
    }

    private var hasCompletedSetup: Bool {
        get { UserDefaults.standard.bool(forKey: Self.setupCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.setupCompletedKey) }
    }

    private var automaticUpdateChecksEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: Self.automaticUpdateChecksKey) as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.automaticUpdateChecksKey) }
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = Self.createStatusIcon()
        }
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshSetupWindow()
            self?.refreshSettingsWindow()
            // 立即刷新幾何,避免 tap 拿舊的螢幕邊界 clamp 游標
            self?.reconcile(summonIfWrong: false)
            // 等系統把螢幕配置穩定下來再召喚 Dock
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.reconcile(summonIfWrong: true)
            }
        }

        // 定期對帳:涵蓋權限被授予/撤銷、固定的螢幕消失又出現等情況
        reconcileTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.refreshSetupWindow()
            self?.refreshSettingsWindow()
            self?.reconcile(summonIfWrong: false)
        }

        let trusted = AXIsProcessTrusted()
        let pinned = pinnedUUID.flatMap { DisplayInfo.resolve(uuid: $0) }
        if resolveAndPersistSetupState(trusted: trusted, pinned: pinned).shouldPresentOnboarding {
            openSetupWindow()
        }
        reconcile(summonIfWrong: true)
        performUpdateCheck(trigger: .automatic)
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) {
            [weak self] _ in
            self?.performUpdateCheck(trigger: .automatic)
        }
    }

    // MARK: - 狀態對帳

    /// 冪等:依「想固定哪顆螢幕 × 權限 × 螢幕是否存在」收斂到正確狀態。
    private func reconcile(summonIfWrong: Bool) {
        let trusted = AXIsProcessTrusted()
        let display = pinnedUUID.flatMap { DisplayInfo.resolve(uuid: $0) }
        let setupState = resolveAndPersistSetupState(trusted: trusted, pinned: display)

        guard setupState.isDockControlEligible, let display else {
            // 權限被撤銷 → 自動停止攔截;螢幕不在 → 停止並等使用者重新選擇
            stopGuarding()
            return
        }

        dockGuard.orientation = DockOrientation.current()
        dockGuard.pinnedDisplayID = display.id
        dockGuard.refreshDisplays()
        let wasRunning = dockGuard.isRunning
        let action = GuardReconciliation.afterStart(
            wasRunning: wasRunning,
            startSucceeded: dockGuard.start(),
            summonRequested: summonIfWrong
        )
        guard case let .monitor(shouldSummon) = action else {
            stopGuarding()
            return
        }
        startDockWatchIfNeeded()
        // 剛從停止轉為啟動(例如使用者剛授權完)也要立刻召喚,
        // 不然要等 dockWatchTimer 首次觸發,看起來像沒生效
        if shouldSummon {
            summonIfOnWrongScreen()
        }
    }

    private func stopGuarding() {
        dockGuard.stop()
        dockWatchTimer?.invalidate()
        dockWatchTimer = nil
    }

    private func startDockWatchIfNeeded() {
        guard dockWatchTimer == nil else { return }
        dockWatchTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.summonIfOnWrongScreen()
        }
    }

    private func summonIfOnWrongScreen() {
        guard dockGuard.isRunning,
              let pinned = dockGuard.pinnedDisplayID,
              !DockMover.isAnyMouseButtonPressed(),
              let current = DockMover.dockDisplayID(),
              current != pinned else { return }
        DockMover.summonDock(to: pinned, orientation: DockOrientation.current())
    }

    // MARK: - 選單

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let trusted = AXIsProcessTrusted()
        let displays = DisplayInfo.active()
        let pinned = pinnedUUID.flatMap { uuid in displays.first { $0.uuid == uuid } }

        menu.addItem(disabledItem("Berth"))
        menu.addItem(disabledItem(statusText(trusted: trusted, pinned: pinned)))
        menu.addItem(.separator())

        let setupState = resolveAndPersistSetupState(trusted: trusted, pinned: pinned)
        if setupState.shouldPresentOnboarding {
            let setup = NSMenuItem(
                title: AppStrings.continueSetup,
                action: #selector(openSetupWindow),
                keyEquivalent: ""
            )
            setup.target = self
            menu.addItem(setup)
            menu.addItem(.separator())
        }

        menu.addItem(disabledItem(AppStrings.pinDockTo))
        for display in displays {
            let title = display.isMain ? display.name + AppStrings.mainDisplaySuffix : display.name
            let item = NSMenuItem(title: title, action: #selector(screenItemClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = display
            item.state = pinned == display ? .on : .off
            menu.addItem(item)
        }
        let unpin = NSMenuItem(title: AppStrings.unpin, action: #selector(unpinClicked), keyEquivalent: "")
        unpin.target = self
        unpin.isEnabled = pinnedUUID != nil
        menu.addItem(unpin)
        menu.addItem(.separator())

        let summon = NSMenuItem(
            title: AppStrings.bringDockBack,
            action: #selector(summonClicked),
            keyEquivalent: ""
        )
        summon.target = self
        summon.isEnabled = setupState.isDockControlEligible
        menu.addItem(summon)
        menu.addItem(.separator())

        let settings = NSMenuItem(
            title: AppStrings.settings,
            action: #selector(openSettingsWindow),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        let updatePresentation = UpdateCheckPresentation.resolve(
            isChecking: isCheckingForUpdates,
            result: updateCheckCoordinator.lastAttemptResult,
            knownAvailableRelease: updateCheckCoordinator.knownAvailableRelease
        )
        switch updatePresentation {
        case let .current(version):
            menu.addItem(disabledItem(AppStrings.settingsUpdatesCurrent(version: version)))
        case let .available(version):
            menu.addItem(disabledItem(AppStrings.updateAvailable(version: version)))
        case let .failed(knownAvailableVersion):
            menu.addItem(disabledItem(AppStrings.settingsUpdatesFailed))
            if let knownAvailableVersion {
                menu.addItem(disabledItem(AppStrings.updateAvailable(version: knownAvailableVersion)))
            }
        case .idle, .checking:
            break
        }
        let checkForUpdates = NSMenuItem(
            title: isCheckingForUpdates ? AppStrings.settingsUpdatesChecking : AppStrings.checkForUpdates,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkForUpdates.target = self
        checkForUpdates.isEnabled = !isCheckingForUpdates
        menu.addItem(checkForUpdates)
        if updatePresentation.showsInstructions {
            let viewInstructions = NSMenuItem(
                title: AppStrings.viewUpdateInstructions,
                action: #selector(openUpdateInstructions),
                keyEquivalent: ""
            )
            viewInstructions.target = self
            menu.addItem(viewInstructions)
        }
        menu.addItem(.separator())

        let quit = NSMenuItem(title: AppStrings.quit, action: #selector(quitClicked), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func statusText(trusted: Bool, pinned: DisplayInfo?) -> String {
        guard pinnedUUID != nil else { return AppStrings.unpinnedStatus }
        guard trusted else { return AppStrings.waitingForAccessibilityStatus }
        guard let pinned else { return AppStrings.pinnedDisplayMissingStatus }
        return dockGuard.isRunning
            ? AppStrings.pinnedStatus(displayName: pinned.name)
            : AppStrings.dockControlInactiveStatus
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - 動作

    @objc private func screenItemClicked(_ sender: NSMenuItem) {
        guard let display = sender.representedObject as? DisplayInfo else { return }
        pinnedUUID = display.uuid
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
        refreshSetupWindow()
        refreshSettingsWindow()
        reconcile(summonIfWrong: true)
    }

    @objc private func unpinClicked() {
        pinnedUUID = nil
        refreshSetupWindow()
        refreshSettingsWindow()
        reconcile(summonIfWrong: false)
    }

    @objc private func openSetupWindow() {
        let controller: SetupWindowController
        if let setupWindowController {
            controller = setupWindowController
        } else {
            controller = SetupWindowController()
            controller.onDisplaySelected = { [weak self] uuid in
                self?.pinnedUUID = uuid
                self?.refreshSetupWindow()
                self?.reconcile(summonIfWrong: false)
            }
            controller.onRequestAccessibility = { [weak self] in
                self?.requestAccessibilityPermission()
            }
            controller.onOpenAccessibilitySettings = { [weak self] in
                self?.openAccessibilitySettings()
            }
            controller.onOpenDesktopSettings = { [weak self] in
                self?.openDesktopSettings()
            }
            controller.onClose = { [weak self] in
                self?.setupRefreshTimer?.invalidate()
                self?.setupRefreshTimer = nil
                self?.reconcile(summonIfWrong: false)
            }
            setupWindowController = controller
        }

        controller.showWindow(nil)
        refreshSetupWindow()
        NSApp.activate(ignoringOtherApps: true)
        setupRefreshTimer?.invalidate()
        setupRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshSetupWindow()
            self?.reconcile(summonIfWrong: false)
        }
    }

    private func refreshSetupWindow() {
        guard let controller = setupWindowController, controller.window?.isVisible == true else { return }
        let displays = DisplayInfo.active()
        let trusted = AXIsProcessTrusted()
        let pinned = pinnedUUID.flatMap { uuid in displays.first { $0.uuid == uuid } }
        controller.update(
            displays: displays,
            pinnedUUID: pinnedUUID,
            isAccessibilityTrusted: trusted,
            state: resolveAndPersistSetupState(trusted: trusted, pinned: pinned)
        )
    }

    @objc private func openSettingsWindow() {
        let controller: SettingsWindowController
        if let settingsWindowController {
            controller = settingsWindowController
        } else {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                ?? "—"
            controller = SettingsWindowController(version: version)
            controller.onDisplaySelected = { [weak self] uuid in
                self?.pinnedUUID = uuid
                self?.refreshSetupWindow()
                self?.refreshSettingsWindow()
                self?.reconcile(summonIfWrong: false)
            }
            controller.onRequestAccessibility = { [weak self] in
                self?.requestAccessibilityPermission()
            }
            controller.onOpenAccessibilitySettings = { [weak self] in
                self?.openAccessibilitySettings()
            }
            controller.onToggleLaunchAtLogin = { [weak self] in
                self?.toggleLoginItem()
            }
            controller.onOpenLoginItemsSettings = { [weak self] in
                self?.openLoginItemsSettings()
            }
            controller.onOpenProject = { [weak self] in
                self?.openProject()
            }
            controller.onToggleAutomaticUpdateChecks = { [weak self] in
                self?.toggleAutomaticUpdateChecks()
            }
            controller.onCheckForUpdates = { [weak self] in
                self?.performUpdateCheck(trigger: .manual)
            }
            controller.onViewUpdateInstructions = { [weak self] in
                self?.openUpdateInstructions()
            }
            controller.onClose = { [weak self] in
                self?.settingsRefreshTimer?.invalidate()
                self?.settingsRefreshTimer = nil
            }
            settingsWindowController = controller
        }

        controller.showWindow(nil)
        controller.window?.deminiaturize(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        refreshSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
        settingsRefreshTimer?.invalidate()
        settingsRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshSettingsWindow()
            self?.reconcile(summonIfWrong: false)
        }
    }

    private func refreshSettingsWindow() {
        guard let controller = settingsWindowController, controller.window?.isVisible == true else { return }
        let displays = DisplayInfo.active()
        let trusted = AXIsProcessTrusted()
        let pinned = pinnedUUID.flatMap { uuid in displays.first { $0.uuid == uuid } }
        _ = resolveAndPersistSetupState(trusted: trusted, pinned: pinned)
        let setupSnapshot = SetupSnapshot(
            hasCompletedSetup: hasCompletedSetup,
            hasPinnedDisplay: pinnedUUID != nil,
            isPinnedDisplayAvailable: pinned != nil,
            isAccessibilityTrusted: trusted
        )
        controller.update(
            displays: displays,
            pinnedUUID: pinnedUUID,
            presentation: SettingsPresentation.resolve(
                setupSnapshot: setupSnapshot,
                launchAtLoginStatus: launchAtLoginStatus()
            )
        )
        controller.updateUpdates(
            automaticChecksEnabled: automaticUpdateChecksEnabled,
            isChecking: isCheckingForUpdates,
            result: updateCheckCoordinator.lastAttemptResult,
            knownAvailableRelease: updateCheckCoordinator.knownAvailableRelease
        )
    }

    private func toggleAutomaticUpdateChecks() {
        automaticUpdateChecksEnabled.toggle()
        refreshSettingsWindow()
        if automaticUpdateChecksEnabled {
            performUpdateCheck(trigger: .automatic)
        }
    }

    @objc private func checkForUpdates() {
        performUpdateCheck(trigger: .manual)
    }

    private func performUpdateCheck(trigger: UpdateCheckTrigger) {
        let now = Date()
        guard !isCheckingForUpdates,
              updateCheckCoordinator.beginCheck(
                  trigger: trigger,
                  automaticChecksEnabled: automaticUpdateChecksEnabled,
                  now: now
              ) else {
            return
        }

        isCheckingForUpdates = true
        refreshSettingsWindow()
        let currentVersion = currentVersion
        let client = latestReleaseClient
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result: UpdateCheckResult
            do {
                let release = try await client.fetchLatestRelease()
                result = UpdateCheckPolicy.evaluate(
                    currentVersion: currentVersion,
                    release: release
                )
            } catch {
                result = .failed
            }
            self.completeUpdateCheck(result, trigger: trigger)
        }
    }

    private func completeUpdateCheck(
        _ result: UpdateCheckResult,
        trigger: UpdateCheckTrigger
    ) {
        isCheckingForUpdates = false
        let shouldNotify = updateCheckCoordinator.completeCheck(result, trigger: trigger)
        refreshSettingsWindow()

        guard shouldNotify,
              case let .updateAvailable(_, release) = result else {
            return
        }
        showUpdateAlert(release: release)
    }

    private func showUpdateAlert(release: UpdateRelease) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = AppStrings.updateAlertTitle
        alert.informativeText = AppStrings.updateAlertMessage(version: release.version)
        alert.addButton(withTitle: AppStrings.viewUpdateInstructions)
        alert.addButton(withTitle: AppStrings.updateAlertLater)
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openUpdateInstructions()
        }
    }

    @objc private func openUpdateInstructions() {
        NSWorkspace.shared.open(Self.updateInstructionsURL)
    }

    private func resolveAndPersistSetupState(trusted: Bool, pinned: DisplayInfo?) -> SetupState {
        var snapshot = SetupSnapshot(
            hasCompletedSetup: hasCompletedSetup,
            hasPinnedDisplay: pinnedUUID != nil,
            isPinnedDisplayAvailable: pinned != nil,
            isAccessibilityTrusted: trusted
        )
        var state = SetupState.resolve(snapshot)
        if state.shouldRecordCompletion {
            hasCompletedSetup = true
            snapshot = SetupSnapshot(
                hasCompletedSetup: true,
                hasPinnedDisplay: snapshot.hasPinnedDisplay,
                isPinnedDisplayAvailable: snapshot.isPinnedDisplayAvailable,
                isAccessibilityTrusted: snapshot.isAccessibilityTrusted
            )
            state = SetupState.resolve(snapshot)
        }
        return state
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        refreshSetupWindow()
        refreshSettingsWindow()
    }

    @objc private func summonClicked() {
        guard let uuid = pinnedUUID, let display = DisplayInfo.resolve(uuid: uuid) else { return }
        DockMover.summonDock(to: display.id, orientation: DockOrientation.current())
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func openDesktopSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openLoginItemsSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private func openProject() {
        guard let url = URL(string: "https://github.com/shihyuho/berth") else { return }
        NSWorkspace.shared.open(url)
    }

    private func launchAtLoginStatus() -> SettingsPresentation.LaunchAtLoginStatus {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return .unavailable }
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("切換登入啟動失敗:\(error)")
        }
        refreshSettingsWindow()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }

    // MARK: - 圖示繪製

    private static func createStatusIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath()
            path.lineWidth = 1.3
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            // 頂部圓環
            let ringRect = NSRect(x: 7.25, y: 12.5, width: 3.5, height: 3.5)
            let ring = NSBezierPath(ovalIn: ringRect)
            ring.lineWidth = 1.2
            ring.stroke()

            // 橫桿
            path.move(to: NSPoint(x: 4.5, y: 11.5))
            path.line(to: NSPoint(x: 13.5, y: 11.5))

            // 中央垂直桿
            path.move(to: NSPoint(x: 9.0, y: 12.5))
            path.line(to: NSPoint(x: 9.0, y: 3.0))

            // 底部弧度 (錨臂)
            path.move(to: NSPoint(x: 4.0, y: 7.5))
            path.curve(
                to: NSPoint(x: 14.0, y: 7.5),
                controlPoint1: NSPoint(x: 4.0, y: 2.0),
                controlPoint2: NSPoint(x: 14.0, y: 2.0)
            )
            path.stroke()

            // 左右兩側倒鉤
            let leftFluke = NSBezierPath()
            leftFluke.move(to: NSPoint(x: 2.8, y: 6.8))
            leftFluke.line(to: NSPoint(x: 4.0, y: 8.2))
            leftFluke.line(to: NSPoint(x: 5.2, y: 6.8))
            leftFluke.lineWidth = 1.1
            leftFluke.lineCapStyle = .round
            leftFluke.lineJoinStyle = .round
            leftFluke.stroke()

            let rightFluke = NSBezierPath()
            rightFluke.move(to: NSPoint(x: 12.8, y: 6.8))
            rightFluke.line(to: NSPoint(x: 14.0, y: 8.2))
            rightFluke.line(to: NSPoint(x: 15.2, y: 6.8))
            rightFluke.lineWidth = 1.1
            rightFluke.lineCapStyle = .round
            rightFluke.lineJoinStyle = .round
            rightFluke.stroke()

            return true
        }
        img.isTemplate = true
        return img
    }
}
