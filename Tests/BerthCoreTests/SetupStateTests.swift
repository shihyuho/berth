import XCTest
@testable import BerthCore

final class SetupStateTests: XCTestCase {
    func testNewUserNeedsPinnedDisplay() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: false,
                hasPinnedDisplay: false,
                isPinnedDisplayAvailable: false,
                isAccessibilityTrusted: false
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .needsPinnedDisplay,
                shouldPresentOnboarding: true,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        )
    }

    func testPartiallyConfiguredUserNeedsAccessibilityPermission() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: false,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: true,
                isAccessibilityTrusted: false
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .needsAccessibilityPermission,
                shouldPresentOnboarding: true,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        )
    }

    func testValidConfigurationRecordsCompletionForNewOrMigratedUser() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: false,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: true,
                isAccessibilityTrusted: true
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .ready,
                shouldPresentOnboarding: false,
                shouldRecordCompletion: true,
                isDockControlEligible: true
            )
        )
    }

    func testMissingPinnedDisplayAfterCompletionRequiresRecoveryWithoutOnboarding() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: true,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: false,
                isAccessibilityTrusted: true
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .pinnedDisplayMissing,
                shouldPresentOnboarding: false,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        )
    }

    func testCompletedSetupRemainsReadyWithoutRewritingHistory() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: true,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: true,
                isAccessibilityTrusted: true
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .ready,
                shouldPresentOnboarding: false,
                shouldRecordCompletion: false,
                isDockControlEligible: true
            )
        )
    }

    func testRevokedPermissionAfterCompletionRequiresRecoveryWithoutOnboarding() {
        let state = SetupState.resolve(
            SetupSnapshot(
                hasCompletedSetup: true,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: true,
                isAccessibilityTrusted: false
            )
        )

        XCTAssertEqual(
            state,
            SetupState(
                readiness: .needsAccessibilityPermission,
                shouldPresentOnboarding: false,
                shouldRecordCompletion: false,
                isDockControlEligible: false
            )
        )
    }
}
