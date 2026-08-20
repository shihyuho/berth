import AppKit
import BerthCore
import CoreGraphics

private let tapCallback: CGEventTapCallBack = { _, type, event, refcon in
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let dockGuard = Unmanaged<DockGuard>.fromOpaque(refcon).takeUnretainedValue()
    return dockGuard.handle(type: type, event: event)
}

/// 用 event tap 把游標擋在「非固定螢幕」的 Dock 邊緣之外,
/// 讓 macOS 的「推到邊緣把 Dock 拉過來」手勢永遠不會在其他螢幕成立。
final class DockGuard {
    private(set) var isRunning = false
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var pinnedDisplayID: CGDirectDisplayID?
    var orientation: DockOrientation = .bottom
    private var displayBounds: [DisplayBounds] = []

    func refreshDisplays() {
        displayBounds = DisplayInfo.activeDisplayBounds()
    }

    @discardableResult
    func start() -> Bool {
        if isRunning { return true }
        refreshDisplays()
        let mask: CGEventMask =
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: tapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        return true
    }

    func stop() {
        guard isRunning else { return }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        isRunning = false
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 系統會在逾時或使用者輸入壓力大時暫停 tap;權限還在就重新啟用。
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap, AXIsProcessTrusted() {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let restricted = DockGeometry.restrictedLocation(
            event.location,
            pinnedDisplayID: pinnedDisplayID,
            orientation: orientation,
            displays: displayBounds
        )
        if restricted != event.location {
            event.location = restricted
        }
        return Unmanaged.passUnretained(event)
    }
}
