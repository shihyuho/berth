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
            XCTAssertFalse(wrappingLabels.isEmpty)

            for label in wrappingLabels {
                XCTAssertLessThanOrEqual(
                    label.alignmentRect(forFrame: label.frame).width,
                    stack.bounds.width + 0.5,
                    "Wrapping label is wider than its section stack"
                )
            }
        }
    }

    func testGeneralSectionOpensLanguageAndRegion() throws {
        var openedURLs: [URL] = []
        let opener = SystemSettingsOpener(
            openURL: { url, completion in
                openedURLs.append(url)
                completion(true)
            },
            systemSettingsURL: { nil },
            openApplication: { _, _ in XCTFail("Fallback should not open") }
        )
        let controller = makeController(
            languageContent: .english,
            systemSettingsOpener: opener
        )

        let contentView = try XCTUnwrap(controller.window?.contentView)
        let button = try XCTUnwrap(
            contentView.descendants(of: NSButton.self).first {
                $0.identifier?.rawValue == "settings.appLanguage.openSettings"
            }
        )
        button.performClick(nil)

        XCTAssertEqual(
            openedURLs,
            [URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")!]
        )
    }

    func testGeneralSectionShowsLocalizedErrorWhenHandoffFails() throws {
        let opener = SystemSettingsOpener(
            openURL: { _, completion in completion(false) },
            systemSettingsURL: { nil },
            openApplication: { _, _ in XCTFail("No fallback URL should be available") }
        )
        let controller = makeController(
            languageContent: .traditionalChinese,
            systemSettingsOpener: opener
        )
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let button = try XCTUnwrap(
            contentView.descendants(of: NSButton.self).first {
                $0.identifier?.rawValue == "settings.appLanguage.openSettings"
            }
        )
        let errorLabel = try XCTUnwrap(
            contentView.descendants(of: NSTextField.self).first {
                $0.identifier?.rawValue == "settings.appLanguage.openError"
            }
        )

        button.performClick(nil)
        let errorAppeared = expectation(description: "localized handoff error appears")
        DispatchQueue.main.async {
            if !errorLabel.isHidden {
                errorAppeared.fulfill()
            }
        }
        wait(for: [errorAppeared], timeout: 1)

        XCTAssertEqual(errorLabel.stringValue, AppLanguageSettingsContent.traditionalChinese.openError)
    }

    func testSupportedLanguageContentAndErrorFitStableWindow() throws {
        for languageContent in [AppLanguageSettingsContent.english, .traditionalChinese] {
            let controller = makeController(languageContent: languageContent)
            let sizeBeforeError = try XCTUnwrap(controller.window).frame.size

            controller.showLanguageSettingsError()
            controller.window?.contentView?.layoutSubtreeIfNeeded()

            let window = try XCTUnwrap(controller.window)
            XCTAssertEqual(window.frame.size, sizeBeforeError)
            XCTAssertEqual(window.frame.width, 520)

            let contentView = try XCTUnwrap(window.contentView)
            let sections = contentView.descendants(of: NSBox.self)
            XCTAssertEqual(sections.count, 4)
            for section in sections {
                XCTAssertTrue(
                    contentView.bounds.insetBy(dx: -0.5, dy: -0.5).contains(
                        section.convert(section.bounds, to: contentView)
                    ),
                    "Section \(section.title) extends beyond the Settings content view"
                )
            }

            let errorLabel = try XCTUnwrap(
                contentView.descendants(of: NSTextField.self).first {
                    $0.identifier?.rawValue == "settings.appLanguage.openError"
                }
            )
            XCTAssertFalse(errorLabel.isHidden)
            XCTAssertEqual(errorLabel.stringValue, languageContent.openError)
            let errorContainer = try XCTUnwrap(errorLabel.superview)
            XCTAssertLessThanOrEqual(
                errorLabel.alignmentRect(forFrame: errorLabel.frame).width,
                errorContainer.bounds.width + 0.5
            )
        }
    }

    private func makeController() -> SettingsWindowController {
        makeController(languageContent: .english)
    }

    private func makeController(
        languageContent: AppLanguageSettingsContent,
        systemSettingsOpener: SystemSettingsOpener = SystemSettingsOpener(
            openURL: { _, completion in completion(true) },
            systemSettingsURL: { nil },
            openApplication: { _, completion in completion(false) }
        )
    ) -> SettingsWindowController {
        _ = NSApplication.shared
        let controller = SettingsWindowController(
            version: "test",
            languageContent: languageContent,
            systemSettingsOpener: systemSettingsOpener
        )
        controller.window?.contentView?.layoutSubtreeIfNeeded()
        return controller
    }
}

private extension AppLanguageSettingsContent {
    static let english = AppLanguageSettingsContent(
        generalTitle: "General",
        languageLabel: "App Language",
        effectiveLanguage: "Currently using: English",
        instructions: "In Language & Region, add or select Berth under Applications, choose a language, then reopen Berth.",
        openSettings: "Open Language & Region…",
        openError: "Couldn’t open System Settings. Open System Settings → General → Language & Region → Applications."
    )

    static let traditionalChinese = AppLanguageSettingsContent(
        generalTitle: "一般",
        languageLabel: "App 語言",
        effectiveLanguage: "目前使用：繁體中文（台灣）",
        instructions: "請在「語言與地區」的「應用程式」區塊加入或選擇 Berth、選取語言，然後重新開啟 Berth。",
        openSettings: "開啟「語言與地區」…",
        openError: "無法開啟「系統設定」。請前往「系統設定」→「一般」→「語言與地區」→「應用程式」。"
    )
}

private extension NSView {
    func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { view in
            (view as? T).map { [$0] } ?? view.descendants(of: type)
        }
    }
}
