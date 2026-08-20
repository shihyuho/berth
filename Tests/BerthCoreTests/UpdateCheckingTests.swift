import Foundation
import XCTest

@testable import BerthCore

final class UpdateCheckingTests: XCTestCase {
    private let releaseURL = URL(string: "https://github.com/shihyuho/berth/releases/tag/1.3.0")!

    func testNewerPublishedReleaseIsAvailable() {
        let result = UpdateCheckPolicy.evaluate(
            currentVersion: "1.2.0",
            release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
        )

        XCTAssertEqual(
            result,
            .updateAvailable(
                currentVersion: "1.2.0",
                release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
            )
        )
    }

    func testEqualReleaseIsCurrent() {
        let result = UpdateCheckPolicy.evaluate(
            currentVersion: "1.3.0",
            release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
        )

        XCTAssertEqual(result, .upToDate(currentVersion: "1.3.0"))
    }

    func testOlderReleaseIsNotOfferedAsAnUpdate() {
        let result = UpdateCheckPolicy.evaluate(
            currentVersion: "1.10.0",
            release: UpdateRelease(version: "1.9.9", detailsURL: releaseURL)
        )

        XCTAssertEqual(result, .upToDate(currentVersion: "1.10.0"))
    }

    func testMalformedReleaseVersionFailsTheCheck() {
        let result = UpdateCheckPolicy.evaluate(
            currentVersion: "1.2.0",
            release: UpdateRelease(version: "latest", detailsURL: releaseURL)
        )

        XCTAssertEqual(result, .failed)
    }

    func testManualCheckBypassesAutomaticSchedule() {
        let now = Date(timeIntervalSince1970: 100_000)

        XCTAssertTrue(
            UpdateCheckPolicy.shouldCheck(
                trigger: .manual,
                automaticChecksEnabled: false,
                lastCheckedAt: now,
                now: now
            )
        )
    }

    func testFirstAutomaticCheckIsDueWhenEnabled() {
        XCTAssertTrue(
            UpdateCheckPolicy.shouldCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                lastCheckedAt: nil,
                now: Date(timeIntervalSince1970: 100_000)
            )
        )
    }

    func testAutomaticCheckIsNotDueWhenDisabled() {
        XCTAssertFalse(
            UpdateCheckPolicy.shouldCheck(
                trigger: .automatic,
                automaticChecksEnabled: false,
                lastCheckedAt: nil,
                now: Date(timeIntervalSince1970: 100_000)
            )
        )
    }

    func testAutomaticCheckRemainsThrottledUntilTwentyFourHoursPass() {
        let lastCheckedAt = Date(timeIntervalSince1970: 100_000)

        XCTAssertFalse(
            UpdateCheckPolicy.shouldCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                lastCheckedAt: lastCheckedAt,
                now: lastCheckedAt.addingTimeInterval((24 * 60 * 60) - 1)
            )
        )
        XCTAssertTrue(
            UpdateCheckPolicy.shouldCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                lastCheckedAt: lastCheckedAt,
                now: lastCheckedAt.addingTimeInterval(24 * 60 * 60)
            )
        )
    }

    func testAvailableReleasePromptsOnlyOncePerVersion() {
        let result = UpdateCheckResult.updateAvailable(
            currentVersion: "1.2.0",
            release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
        )

        XCTAssertTrue(
            UpdateCheckPolicy.shouldNotify(
                result,
                trigger: .automatic,
                lastNotifiedVersion: nil
            )
        )
        XCTAssertFalse(
            UpdateCheckPolicy.shouldNotify(
                result,
                trigger: .automatic,
                lastNotifiedVersion: "1.3.0"
            )
        )
    }

    func testManualCheckNeverPrompts() {
        let result = UpdateCheckResult.updateAvailable(
            currentVersion: "1.2.0",
            release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
        )

        XCTAssertFalse(
            UpdateCheckPolicy.shouldNotify(
                result,
                trigger: .manual,
                lastNotifiedVersion: nil
            )
        )
    }

    func testPresentationCoversEveryUpdateCheckState() {
        XCTAssertEqual(
            UpdateCheckPresentation.resolve(isChecking: false, result: nil),
            .idle
        )
        XCTAssertEqual(
            UpdateCheckPresentation.resolve(isChecking: true, result: .failed),
            .checking
        )
        XCTAssertEqual(
            UpdateCheckPresentation.resolve(
                isChecking: false,
                result: .upToDate(currentVersion: "1.2.0")
            ),
            .current(version: "1.2.0")
        )
        XCTAssertEqual(
            UpdateCheckPresentation.resolve(
                isChecking: false,
                result: .updateAvailable(
                    currentVersion: "1.2.0",
                    release: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
                )
            ),
            .available(version: "1.3.0")
        )
        XCTAssertEqual(
            UpdateCheckPresentation.resolve(isChecking: false, result: .failed),
            .failed
        )
    }

    func testOnlyAvailablePresentationOffersUpdateInstructions() {
        XCTAssertTrue(UpdateCheckPresentation.available(version: "1.3.0").showsInstructions)
        XCTAssertFalse(UpdateCheckPresentation.current(version: "1.2.0").showsInstructions)
        XCTAssertFalse(UpdateCheckPresentation.failed.showsInstructions)
    }
}
