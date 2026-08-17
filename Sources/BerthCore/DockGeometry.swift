import CoreGraphics

public enum DockOrientation: String {
    case bottom
    case left
    case right
}

public struct DisplayBounds: Equatable {
    public let id: CGDirectDisplayID
    public let bounds: CGRect
    public let isMirrored: Bool

    public init(id: CGDirectDisplayID, bounds: CGRect, isMirrored: Bool = false) {
        self.id = id
        self.bounds = bounds
        self.isMirrored = isMirrored
    }
}

public enum DockGeometry {
    private static let margin: CGFloat = 2

    public static func restrictedLocation(
        _ location: CGPoint,
        pinnedDisplayID: CGDirectDisplayID?,
        orientation: DockOrientation,
        displays: [DisplayBounds]
    ) -> CGPoint {
        guard let pinnedDisplayID else {
            return location
        }
        let nonMirroredDisplays = displays.filter { !$0.isMirrored }
        let containingDisplays = nonMirroredDisplays.filter { $0.bounds.contains(location) }
        guard let display = containingDisplays.first,
              !containingDisplays.contains(where: { $0.id == pinnedDisplayID }) else {
            return location
        }

        var restricted = location
        switch orientation {
        case .bottom:
            let beyondEdge = CGPoint(x: location.x, y: display.bounds.maxY + margin)
            if location.y > display.bounds.maxY - margin,
               !nonMirroredDisplays.contains(where: { $0.bounds.contains(beyondEdge) }) {
                restricted.y = display.bounds.maxY - margin
            }
        case .left:
            let beyondEdge = CGPoint(x: display.bounds.minX - margin, y: location.y)
            if location.x < display.bounds.minX + margin,
               !nonMirroredDisplays.contains(where: { $0.bounds.contains(beyondEdge) }) {
                restricted.x = display.bounds.minX + margin
            }
        case .right:
            let beyondEdge = CGPoint(x: display.bounds.maxX + margin, y: location.y)
            if location.x > display.bounds.maxX - margin,
               !nonMirroredDisplays.contains(where: { $0.bounds.contains(beyondEdge) }) {
                restricted.x = display.bounds.maxX - margin
            }
        }
        return restricted
    }
}
