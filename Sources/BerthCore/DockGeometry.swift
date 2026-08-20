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

    public static func summonLocation(
        for displayID: CGDirectDisplayID,
        orientation: DockOrientation,
        displays: [DisplayBounds]
    ) -> CGPoint? {
        let nonMirroredDisplays = displays.filter { !$0.isMirrored }
        guard let display = nonMirroredDisplays.first(where: { $0.id == displayID }) else {
            return nil
        }
        let otherDisplays = nonMirroredDisplays.filter { $0.id != displayID }
        let bounds = display.bounds
        let preferredCoordinate: CGFloat
        let validRange: ClosedRange<CGFloat>
        let candidatesFromDisplay: (CGRect) -> [CGFloat]
        let location: (CGFloat) -> CGPoint
        let beyondEdge: (CGFloat) -> CGPoint

        switch orientation {
        case .bottom:
            preferredCoordinate = bounds.midX
            validRange = (bounds.minX + margin)...(bounds.maxX - margin)
            candidatesFromDisplay = { [$0.minX - margin, $0.maxX + margin] }
            location = { CGPoint(x: $0, y: bounds.maxY - 1) }
            beyondEdge = { CGPoint(x: $0, y: bounds.maxY + margin) }
        case .left:
            preferredCoordinate = bounds.midY
            validRange = (bounds.minY + margin)...(bounds.maxY - margin)
            candidatesFromDisplay = { [$0.minY - margin, $0.maxY + margin] }
            location = { CGPoint(x: bounds.minX, y: $0) }
            beyondEdge = { CGPoint(x: bounds.minX - margin, y: $0) }
        case .right:
            preferredCoordinate = bounds.midY
            validRange = (bounds.minY + margin)...(bounds.maxY - margin)
            candidatesFromDisplay = { [$0.minY - margin, $0.maxY + margin] }
            location = { CGPoint(x: bounds.maxX - 1, y: $0) }
            beyondEdge = { CGPoint(x: bounds.maxX + margin, y: $0) }
        }

        var candidates = [preferredCoordinate, validRange.lowerBound, validRange.upperBound]
        candidates += otherDisplays.flatMap { candidatesFromDisplay($0.bounds) }
        return candidates
            .filter { validRange.contains($0) }
            .filter { coordinate in
                let point = beyondEdge(coordinate)
                return !otherDisplays.contains(where: { $0.bounds.contains(point) })
            }
            .min(by: {
                abs($0 - preferredCoordinate) < abs($1 - preferredCoordinate)
            })
            .map(location)
    }

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
