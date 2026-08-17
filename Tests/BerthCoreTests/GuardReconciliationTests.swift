import XCTest
import BerthCore

final class GuardReconciliationTests: XCTestCase {
    func testMissingAccessibilityPermissionStopsGuarding() {
        let eligibility = GuardReconciliation.eligibility(
            isTrusted: false,
            hasPinnedDisplay: true
        )

        XCTAssertEqual(eligibility, .stop)
    }

    func testNewlyStartedGuardBeginsMonitoringAndSummonsDock() {
        let action = GuardReconciliation.afterStart(
            wasRunning: false,
            startSucceeded: true,
            summonRequested: false
        )

        XCTAssertEqual(action, .monitor(summon: true))
    }

    func testMissingPinnedDisplayStopsGuarding() {
        let eligibility = GuardReconciliation.eligibility(
            isTrusted: true,
            hasPinnedDisplay: false
        )

        XCTAssertEqual(eligibility, .stop)
    }

    func testTrustedPinnedDisplayStartsGuarding() {
        let eligibility = GuardReconciliation.eligibility(
            isTrusted: true,
            hasPinnedDisplay: true
        )

        XCTAssertEqual(eligibility, .start)
    }

    func testFailedGuardStartStopsGuarding() {
        let action = GuardReconciliation.afterStart(
            wasRunning: false,
            startSucceeded: false,
            summonRequested: true
        )

        XCTAssertEqual(action, .stop)
    }

    func testRunningGuardContinuesMonitoringWithoutSummon() {
        let action = GuardReconciliation.afterStart(
            wasRunning: true,
            startSucceeded: true,
            summonRequested: false
        )

        XCTAssertEqual(action, .monitor(summon: false))
    }

    func testRequestedReconciliationSummonsForRunningGuard() {
        let action = GuardReconciliation.afterStart(
            wasRunning: true,
            startSucceeded: true,
            summonRequested: true
        )

        XCTAssertEqual(action, .monitor(summon: true))
    }
}
