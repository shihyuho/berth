import AppKit
import BerthCore
import XCTest

@testable import Berth

final class SettingsWindowControllerLayoutTests: XCTestCase {
    func testUpdatesSectionShowsPersistentAvailableVersionAndActions() throws {
        let controller = makeController()
        controller.updateUpdates(
            automaticChecksEnabled: true,
            isChecking: false,
            result: .updateAvailable(
                currentVersion: "1.2.0",
                release: UpdateRelease(
                    version: "1.3.0",
                    detailsURL: URL(string: "https://github.com/shihyuho/berth/releases/tag/1.3.0")!
                )
            )
        )

        let contentView = try XCTUnwrap(controller.window?.contentView)
        let automaticToggle = try XCTUnwrap(
            contentView.descendants(of: NSButton.self).first {
                $0.identifier?.rawValue == "settings.updates.automatic"
            }
        )
        let checkButton = try XCTUnwrap(
            contentView.descendants(of: NSButton.self).first {
                $0.identifier?.rawValue == "settings.updates.check"
            }
        )
        let viewButton = try XCTUnwrap(
            contentView.descendants(of: NSButton.self).first {
                $0.identifier?.rawValue == "settings.updates.view"
            }
        )
        let status = try XCTUnwrap(
            contentView.descendants(of: NSTextField.self).first {
                $0.identifier?.rawValue == "settings.updates.status"
            }
        )

        XCTAssertEqual(automaticToggle.state, .on)
        XCTAssertTrue(checkButton.isEnabled)
        XCTAssertFalse(viewButton.isHidden)
        XCTAssertTrue(status.stringValue.contains("1.3.0"))
    }

    func testWrappingLabelsStayWithinTheirSectionStacks() throws {
        let controller = makeController()
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let sections = contentView.descendants(of: NSBox.self)
        XCTAssertEqual(sections.count, 5)

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
        for (languageContent, updateContent) in [
            (AppLanguageSettingsContent.english, UpdateSettingsContent.english),
            (.traditionalChinese, .traditionalChinese),
        ] {
            let controller = makeController(
                languageContent: languageContent,
                updateContent: updateContent
            )
            let sizeBeforeError = try XCTUnwrap(controller.window).frame.size

            populateLongestStatusContent(in: controller)
            controller.showLanguageSettingsError()
            controller.window?.contentView?.layoutSubtreeIfNeeded()

            let window = try XCTUnwrap(controller.window)
            XCTAssertEqual(window.frame.size, sizeBeforeError)

            let contentView = try XCTUnwrap(window.contentView)
            XCTAssertEqual(contentView.bounds.width, 520)
            XCTAssertEqual(contentView.bounds.height, 762)
            let sections = contentView.descendants(of: NSBox.self)
            XCTAssertEqual(sections.count, 5)
            for section in sections {
                XCTAssertTrue(
                    contentView.bounds.insetBy(dx: -0.5, dy: -0.5).contains(
                        section.convert(section.bounds, to: contentView)
                    ),
                    "Section \(section.title) extends beyond the Settings content view"
                )
                let sectionContent = try XCTUnwrap(section.contentView)
                let stack = try XCTUnwrap(
                    sectionContent.subviews.compactMap { $0 as? NSStackView }.first
                )
                assertVisibleArrangedSubviewsFitWithoutOverlap(in: stack)
            }

            let visibleWrappingLabels = contentView.descendants(of: NSTextField.self)
                .filter { !$0.isHidden && $0.cell?.wraps == true }
            XCTAssertTrue(visibleWrappingLabels.allSatisfy { !$0.stringValue.isEmpty })

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

    private func populateLongestStatusContent(in controller: SettingsWindowController) {
        let missingPinnedUUID = "missing-pinned-display"
        controller.update(
            displays: [
                DisplayInfo(
                    id: 1,
                    uuid: "available-display",
                    name: "A representative connected display with a long localized name",
                    isMain: true
                ),
            ],
            pinnedUUID: missingPinnedUUID,
            presentation: SettingsPresentation.resolve(
                setupSnapshot: SetupSnapshot(
                    hasCompletedSetup: true,
                    hasPinnedDisplay: true,
                    isPinnedDisplayAvailable: false,
                    isAccessibilityTrusted: false
                ),
                launchAtLoginStatus: .requiresApproval
            )
        )
        controller.updateUpdates(
            automaticChecksEnabled: true,
            isChecking: false,
            result: .updateAvailable(
                currentVersion: "1.2.0",
                release: UpdateRelease(
                    version: "100.200.300",
                    detailsURL: URL(string: "https://example.com/releases/100.200.300")!
                )
            )
        )
    }

    private func assertVisibleArrangedSubviewsFitWithoutOverlap(
        in stack: NSStackView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        stack.layoutSubtreeIfNeeded()
        let visibleSubviews = stack.arrangedSubviews.filter { !$0.isHidden }

        for view in visibleSubviews {
            XCTAssertTrue(
                stack.bounds.insetBy(dx: -0.5, dy: -0.5).contains(
                    view.alignmentRect(forFrame: view.frame)
                ),
                "Visible arranged subview extends beyond its section stack",
                file: file,
                line: line
            )
        }

        for (index, view) in visibleSubviews.enumerated() {
            for laterView in visibleSubviews.dropFirst(index + 1) {
                XCTAssertFalse(
                    view.frame.intersects(laterView.frame),
                    "Visible arranged subviews overlap",
                    file: file,
                    line: line
                )
            }
        }
    }

    private func makeController() -> SettingsWindowController {
        makeController(languageContent: .english)
    }

    private func makeController(
        languageContent: AppLanguageSettingsContent,
        updateContent: UpdateSettingsContent = .english,
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
            systemSettingsOpener: systemSettingsOpener,
            updateContent: updateContent
        )
        controller.window?.contentView?.layoutSubtreeIfNeeded()
        return controller
    }
}

private extension UpdateSettingsContent {
    static let english = UpdateSettingsContent(
        title: "Updates",
        automaticChecks: "Check for updates automatically",
        idle: "Berth checks GitHub Releases for new versions.",
        checking: "Checking for updates…",
        current: { "Berth \($0) is up to date." },
        available: { "Berth \($0) is available." },
        failed: "Couldn’t check for updates. Try again later.",
        check: "Check for Updates…",
        viewInstructions: "View Update Instructions…"
    )

    static let traditionalChinese = UpdateSettingsContent(
        title: "更新",
        automaticChecks: "自動檢查更新",
        idle: "Berth 會從 GitHub Releases 檢查新版本。",
        checking: "正在檢查更新…",
        current: { "Berth \($0) 已是最新版本。" },
        available: { "Berth \($0) 已可更新。" },
        failed: "無法檢查更新，請稍後再試。",
        check: "檢查更新…",
        viewInstructions: "查看更新說明…"
    )
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
