import Foundation
import XCTest

@testable import Berth

final class SystemSettingsOpenerTests: XCTestCase {
    func testLanguageAndRegionDeepLinkSuccessDoesNotUseFallback() {
        var openedURLs: [URL] = []
        let opener = SystemSettingsOpener(
            openURL: { url, completion in
                openedURLs.append(url)
                completion(true)
            },
            systemSettingsURL: {
                XCTFail("System Settings should not be resolved after the deep link succeeds")
                return nil
            },
            openApplication: { _, _ in
                XCTFail("System Settings should not be opened after the deep link succeeds")
            }
        )

        let completed = expectation(description: "open completes")
        opener.openLanguageAndRegion { succeeded in
            XCTAssertTrue(succeeded)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)

        XCTAssertEqual(
            openedURLs,
            [URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")!]
        )
    }

    func testLanguageAndRegionDeepLinkFailureOpensSystemSettings() {
        let systemSettingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        var openedApplicationURLs: [URL] = []
        let opener = SystemSettingsOpener(
            openURL: { _, completion in completion(false) },
            systemSettingsURL: { systemSettingsURL },
            openApplication: { url, completion in
                openedApplicationURLs.append(url)
                completion(true)
            }
        )

        let completed = expectation(description: "fallback completes")
        opener.openLanguageAndRegion { succeeded in
            XCTAssertTrue(succeeded)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)

        XCTAssertEqual(openedApplicationURLs, [systemSettingsURL])
    }

    func testLanguageAndRegionReportsFailureWhenFallbackCannotOpen() {
        let systemSettingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        let opener = SystemSettingsOpener(
            openURL: { _, completion in completion(false) },
            systemSettingsURL: { systemSettingsURL },
            openApplication: { _, completion in completion(false) }
        )

        let completed = expectation(description: "failure completes")
        opener.openLanguageAndRegion { succeeded in
            XCTAssertFalse(succeeded)
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)
    }
}
