import AppKit
import BerthCore

/// 一顆實體螢幕。用 UUID 做持久化識別(displayID 重開機或重接線後可能改變)。
struct DisplayInfo: Equatable {
    let id: CGDirectDisplayID
    let uuid: String
    let name: String
    let isMain: Bool

    static func active() -> [DisplayInfo] {
        activeDisplayIDs().compactMap { id in
            guard let uuid = uuidString(for: id) else { return nil }
            let name = NSScreen.screens.first { $0.displayID == id }?.localizedName
                ?? AppStrings.fallbackDisplayName(displayID: id)
            return DisplayInfo(id: id, uuid: uuid, name: name, isMain: CGDisplayIsMain(id) != 0)
        }
    }

    static func resolve(uuid: String) -> DisplayInfo? {
        active().first { $0.uuid == uuid }
    }

    static func activeDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return Array(ids.prefix(Int(count)))
    }

    static func uuidString(for id: CGDirectDisplayID) -> String? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, cfUUID) as String?
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}

extension DockOrientation {
    /// Dock 目前停靠的邊(讀取系統偏好設定)。
    static func current() -> DockOrientation {
        let value = CFPreferencesCopyAppValue("orientation" as CFString, "com.apple.dock" as CFString) as? String
        return DockOrientation(rawValue: value ?? "bottom") ?? .bottom
    }
}
