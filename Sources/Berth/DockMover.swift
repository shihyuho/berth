import AppKit
import ApplicationServices
import BerthCore

enum DockMover {
    /// 透過 Accessibility 找出 Dock 目前在哪顆螢幕(需要輔助使用權限)。
    static func dockDisplayID() -> CGDirectDisplayID? {
        guard let dockApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.dock").first else { return nil }
        let appElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return nil }

        for child in children {
            var roleRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef) == .success,
                  roleRef as? String == "AXList" else { continue }
            var posRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posRef) == .success,
                  AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeRef) == .success,
                  let posValue = posRef, CFGetTypeID(posValue) == AXValueGetTypeID(),
                  let sizeValue = sizeRef, CFGetTypeID(sizeValue) == AXValueGetTypeID() else { continue }
            var position = CGPoint.zero
            var size = CGSize.zero
            guard AXValueGetValue(posValue as! AXValue, .cgPoint, &position),
                  AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { continue }
            let mid = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
            return DisplayInfo.activeDisplayIDs().first { CGDisplayBounds($0).contains(mid) }
        }
        return nil
    }

    private static let summonQueue = DispatchQueue(label: "com.shihyuho.berth.summon")
    private static var summonInFlight = false // 只在主執行緒讀寫
    private static let summonAttempts = 2
    private static let pressureEventCount = 150
    private static let pressureEventDelay: useconds_t = 10_000
    private static let settlingDelay: useconds_t = 200_000

    /// 在固定螢幕的 Dock 邊緣合成「持續下壓」的滑鼠事件,把 Dock 召回來。
    /// 等同使用者親手把游標推到邊緣再往外壓的手勢。
    /// 必須離開主執行緒執行:event tap 掛在主 run loop,在主執行緒睡眠會堵住
    /// 自己的 tap,游標凍結、合成事件的下壓節奏也會被破壞。
    static func summonDock(to displayID: CGDirectDisplayID, orientation: DockOrientation) {
        guard !summonInFlight else { return }
        summonInFlight = true
        summonQueue.async {
            for _ in 0..<summonAttempts {
                if dockDisplayID() == displayID { break }
                performSummon(displayID: displayID, orientation: orientation)
                usleep(settlingDelay)
            }
            DispatchQueue.main.async { summonInFlight = false }
        }
    }

    private static func performSummon(displayID: CGDirectDisplayID, orientation: DockOrientation) {
        guard let target = DockGeometry.summonLocation(
            for: displayID,
            orientation: orientation,
            displays: DisplayInfo.activeDisplayBounds()
        ) else { return }
        let delta: (x: Int64, y: Int64)
        switch orientation {
        case .bottom:
            delta = (0, 30)
        case .left:
            delta = (-30, 0)
        case .right:
            delta = (30, 0)
        }

        let original = CGEvent(source: nil)?.location
        let source = CGEventSource(stateID: .hidSystemState)
        CGWarpMouseCursorPosition(target)
        for _ in 0..<pressureEventCount {
            guard let event = CGEvent(
                mouseEventSource: source, mouseType: .mouseMoved,
                mouseCursorPosition: target, mouseButton: .left
            ) else { continue }
            event.setIntegerValueField(.mouseEventDeltaX, value: delta.x)
            event.setIntegerValueField(.mouseEventDeltaY, value: delta.y)
            event.post(tap: .cghidEventTap)
            usleep(pressureEventDelay)
        }
        if let original {
            CGWarpMouseCursorPosition(original)
            CGEvent(
                mouseEventSource: source, mouseType: .mouseMoved,
                mouseCursorPosition: original, mouseButton: .left
            )?.post(tap: .cghidEventTap)
        }
    }

    static func isAnyMouseButtonPressed() -> Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
            || CGEventSource.buttonState(.combinedSessionState, button: .right)
            || CGEventSource.buttonState(.combinedSessionState, button: .center)
    }
}
