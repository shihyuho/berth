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

    func testAvailableUpdateSurvivesReconstructionWithoutRepeatingItsPrompt() {
        let now = Date(timeIntervalSince1970: 100_000)
        let store = MemoryUpdateCheckStateStore()
        let release = UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
        var coordinator = UpdateCheckCoordinator(store: store, currentVersion: "1.2.0")

        XCTAssertTrue(
            coordinator.beginCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                now: now
            )
        )
        XCTAssertTrue(
            coordinator.completeCheck(
                .updateAvailable(currentVersion: "1.2.0", release: release),
                trigger: .automatic
            )
        )

        coordinator = UpdateCheckCoordinator(store: store, currentVersion: "1.2.0")

        XCTAssertEqual(
            coordinator.result,
            .updateAvailable(currentVersion: "1.2.0", release: release)
        )
        XCTAssertFalse(
            coordinator.beginCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                now: now.addingTimeInterval(60 * 60)
            )
        )
        XCTAssertTrue(
            coordinator.beginCheck(
                trigger: .automatic,
                automaticChecksEnabled: true,
                now: now.addingTimeInterval(24 * 60 * 60)
            )
        )
        XCTAssertFalse(
            coordinator.completeCheck(
                .updateAvailable(currentVersion: "1.2.0", release: release),
                trigger: .automatic
            )
        )
    }

    func testCurrentResultClearsAStoredAvailableRelease() {
        let store = MemoryUpdateCheckStateStore(
            state: UpdateCheckState(
                availableRelease: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
            )
        )
        let coordinator = UpdateCheckCoordinator(store: store, currentVersion: "1.2.0")

        coordinator.completeCheck(.upToDate(currentVersion: "1.3.0"), trigger: .manual)

        XCTAssertNil(store.state.availableRelease)
        XCTAssertNil(
            UpdateCheckCoordinator(store: store, currentVersion: "1.3.0").result
        )
    }

    func testReconstructionClearsAReleaseThatIsNoLongerNewerThanTheApp() {
        let store = MemoryUpdateCheckStateStore(
            state: UpdateCheckState(
                availableRelease: UpdateRelease(version: "1.3.0", detailsURL: releaseURL)
            )
        )

        let coordinator = UpdateCheckCoordinator(store: store, currentVersion: "1.3.0")

        XCTAssertNil(coordinator.result)
        XCTAssertNil(store.state.availableRelease)
    }
}

private final class MemoryUpdateCheckStateStore: UpdateCheckStateStore {
    var state: UpdateCheckState

    init(state: UpdateCheckState = UpdateCheckState()) {
        self.state = state
    }

    func load() -> UpdateCheckState {
        state
    }

    func save(_ state: UpdateCheckState) {
        self.state = state
    }
}
