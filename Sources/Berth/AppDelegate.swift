import AppKit
import BerthCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let dockGuard = DockGuard()
    private var reconcileTimer: Timer?
    private var dockWatchTimer: Timer?

    private static let pinnedKey = "PinnedDisplayUUID"

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
            // 立即刷新幾何,避免 tap 拿舊的螢幕邊界 clamp 游標
            self?.reconcile(summonIfWrong: false)
            // 等系統把螢幕配置穩定下來再召喚 Dock
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.reconcile(summonIfWrong: true)
            }
        }

        // 定期對帳:涵蓋權限被授予/撤銷、固定的螢幕消失又出現等情況
        reconcileTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.reconcile(summonIfWrong: false)
        }
        reconcile(summonIfWrong: true)
    }

    // MARK: - 狀態對帳

    /// 冪等:依「想固定哪顆螢幕 × 權限 × 螢幕是否存在」收斂到正確狀態。
    private func reconcile(summonIfWrong: Bool) {
        let trusted = AXIsProcessTrusted()
        let display = pinnedUUID.flatMap { DisplayInfo.resolve(uuid: $0) }

        guard GuardReconciliation.eligibility(
            isTrusted: trusted,
            hasPinnedDisplay: display != nil
        ) == .start, let display else {
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
        summon.isEnabled = trusted && pinned != nil
        menu.addItem(summon)
        menu.addItem(.separator())

        if !trusted {
            let openSettings = NSMenuItem(
                title: AppStrings.openAccessibilitySettings,
                action: #selector(openAccessibilitySettings), keyEquivalent: ""
            )
            openSettings.target = self
            menu.addItem(openSettings)
        }
        if Bundle.main.bundleURL.pathExtension == "app" {
            let login = NSMenuItem(
                title: AppStrings.launchAtLogin,
                action: #selector(toggleLoginItem),
                keyEquivalent: ""
            )
            login.target = self
            login.state = SMAppService.mainApp.status == .enabled ? .on : .off
            menu.addItem(login)
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
        reconcile(summonIfWrong: true)
    }

    @objc private func unpinClicked() {
        pinnedUUID = nil
        reconcile(summonIfWrong: false)
    }

    @objc private func summonClicked() {
        guard let uuid = pinnedUUID, let display = DisplayInfo.resolve(uuid: uuid) else { return }
        DockMover.summonDock(to: display.id, orientation: DockOrientation.current())
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
