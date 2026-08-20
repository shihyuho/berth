import AppKit
import XCTest

@testable import Berth

final class SettingsWindowControllerLayoutTests: XCTestCase {
    func testWrappingLabelsStayWithinTheirSectionStacks() throws {
        let controller = makeController()
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let sections = contentView.descendants(of: NSBox.self)
        XCTAssertEqual(sections.count, 4)

        for section in sections {
            let sectionContent = try XCTUnwrap(section.contentView)
            let stack = try XCTUnwrap(sectionContent.subviews.compactMap { $0 as? NSStackView }.first)
            stack.layoutSubtreeIfNeeded()
            let wrappingLabels = stack.arrangedSubviews.compactMap { $0 as? NSTextField }
                .filter { $0.cell?.wraps == true }
            XCTAssertEqual(wrappingLabels.count, 1)

            for label in wrappingLabels {
                XCTAssertLessThanOrEqual(
                    label.alignmentRect(forFrame: label.frame).width,
                    stack.bounds.width + 0.5,
                    "Wrapping label is wider than its section stack"
                )
            }
        }
    }

    private func makeController() -> SettingsWindowController {
        _ = NSApplication.shared
        let controller = SettingsWindowController(version: "test")
        controller.window?.contentView?.layoutSubtreeIfNeeded()
        return controller
    }
}

private extension NSView {
    func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { view in
            (view as? T).map { [$0] } ?? view.descendants(of: type)
        }
    }
}
