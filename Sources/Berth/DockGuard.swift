import AppKit
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
    private var displayBounds: [(id: CGDirectDisplayID, bounds: CGRect)] = []

    /// 游標離 Dock 邊緣的最小距離(px)。到不了邊緣,Dock 就不會被召喚過去。
    private static let margin: CGFloat = 2

    func refreshDisplays() {
        // 排除鏡像螢幕:它與被鏡像者共享相同 bounds,留著會把游標誤判到鏡像那顆
        displayBounds = DisplayInfo.activeDisplayIDs()
            .filter { CGDisplayMirrorsDisplay($0) == 0 }
            .map { ($0, CGDisplayBounds($0)) }
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

        guard let pinned = pinnedDisplayID else { return Unmanaged.passUnretained(event) }
        var location = event.location
        // 多顆螢幕 bounds 可能重疊(鏡像):只要固定螢幕包含游標就放行
        let containing = displayBounds.filter { $0.bounds.contains(location) }
        guard let display = containing.first,
              !containing.contains(where: { $0.id == pinned }) else {
            return Unmanaged.passUnretained(event)
        }

        let bounds = display.bounds
        let margin = Self.margin
        switch orientation {
        case .bottom:
            if location.y > bounds.maxY - margin,
               !hasDisplay(at: CGPoint(x: location.x, y: bounds.maxY + margin)) {
                location.y = bounds.maxY - margin
                event.location = location
            }
        case .left:
            if location.x < bounds.minX + margin,
               !hasDisplay(at: CGPoint(x: bounds.minX - margin, y: location.y)) {
                location.x = bounds.minX + margin
                event.location = location
            }
        case .right:
            if location.x > bounds.maxX - margin,
               !hasDisplay(at: CGPoint(x: bounds.maxX + margin, y: location.y)) {
                location.x = bounds.maxX - margin
                event.location = location
            }
        }
        return Unmanaged.passUnretained(event)
    }

    /// 該點是否落在其他螢幕上 — 是的話代表這條邊是螢幕間的交界,
    /// 擋住會害游標過不去,而且 Dock 也不會出現在這種邊上。
    private func hasDisplay(at point: CGPoint) -> Bool {
        displayBounds.contains { $0.bounds.contains(point) }
    }
}
