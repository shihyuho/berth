import CoreGraphics
import XCTest
import BerthCore

final class DockGeometryTests: XCTestCase {
    func testBottomOuterEdgeKeepsPointerInsideUnpinnedDisplay() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
        ]

        let location = DockGeometry.restrictedLocation(
            CGPoint(x: 150, y: 99.5),
            pinnedDisplayID: 1,
            orientation: .bottom,
            displays: displays
        )

        XCTAssertEqual(location, CGPoint(x: 150, y: 98))
    }

    func testLeftOuterEdgeKeepsPointerInsideUnpinnedDisplay() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
        ]

        let location = DockGeometry.restrictedLocation(
            CGPoint(x: 0.5, y: 50),
            pinnedDisplayID: 1,
            orientation: .left,
            displays: displays
        )

        XCTAssertEqual(location, CGPoint(x: 2, y: 50))
    }

    func testRightOuterEdgeKeepsPointerInsideUnpinnedDisplay() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
        ]

        let location = DockGeometry.restrictedLocation(
            CGPoint(x: 199.5, y: 50),
            pinnedDisplayID: 1,
            orientation: .right,
            displays: displays
        )

        XCTAssertEqual(location, CGPoint(x: 198, y: 50))
    }

    func testDisplayIntersectionDoesNotRestrictPointer() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 0, y: 100, width: 100, height: 100)),
            DisplayBounds(id: 3, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
        ]
        let original = CGPoint(x: 50, y: 99.5)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 3,
            orientation: .bottom,
            displays: displays
        )

        XCTAssertEqual(location, original)
    }

    func testLeftDisplayIntersectionDoesNotRestrictPointer() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 3, bounds: CGRect(x: 200, y: 0, width: 100, height: 100)),
        ]
        let original = CGPoint(x: 100.5, y: 50)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 3,
            orientation: .left,
            displays: displays
        )

        XCTAssertEqual(location, original)
    }

    func testRightDisplayIntersectionDoesNotRestrictPointer() {
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 2, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
            DisplayBounds(id: 3, bounds: CGRect(x: -100, y: 0, width: 100, height: 100)),
        ]
        let original = CGPoint(x: 99.5, y: 50)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 3,
            orientation: .right,
            displays: displays
        )

        XCTAssertEqual(location, original)
    }

    func testOverlappingPinnedDisplayDoesNotRestrictPointer() {
        let sharedBounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let displays = [
            DisplayBounds(id: 2, bounds: sharedBounds),
            DisplayBounds(id: 1, bounds: sharedBounds),
        ]
        let original = CGPoint(x: 50, y: 99.5)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 1,
            orientation: .bottom,
            displays: displays
        )

        XCTAssertEqual(location, original)
    }

    func testMirroredDisplayIsExcludedFromRestriction() {
        let original = CGPoint(x: 150, y: 99.5)
        let displays = [
            DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            DisplayBounds(
                id: 2,
                bounds: CGRect(x: 100, y: 0, width: 100, height: 100),
                isMirrored: true
            ),
        ]

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 1,
            orientation: .bottom,
            displays: displays
        )

        XCTAssertEqual(location, original)
    }

    func testMissingPinnedDisplayLeavesPointerUnchanged() {
        let original = CGPoint(x: 50, y: 99.5)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: nil,
            orientation: .bottom,
            displays: [DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100))]
        )

        XCTAssertEqual(location, original)
    }

    func testPointerOnPinnedDisplayRemainsUnchanged() {
        let original = CGPoint(x: 50, y: 99.5)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 1,
            orientation: .bottom,
            displays: [DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100))]
        )

        XCTAssertEqual(location, original)
    }

    func testPointerAwayFromDockEdgeRemainsUnchanged() {
        let original = CGPoint(x: 150, y: 50)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 1,
            orientation: .bottom,
            displays: [
                DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
                DisplayBounds(id: 2, bounds: CGRect(x: 100, y: 0, width: 100, height: 100)),
            ]
        )

        XCTAssertEqual(location, original)
    }

    func testPointerOutsideKnownDisplaysRemainsUnchanged() {
        let original = CGPoint(x: 250, y: 50)

        let location = DockGeometry.restrictedLocation(
            original,
            pinnedDisplayID: 1,
            orientation: .right,
            displays: [DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100))]
        )

        XCTAssertEqual(location, original)
    }
}
