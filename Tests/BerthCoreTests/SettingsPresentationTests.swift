import XCTest
@testable import BerthCore

final class SettingsPresentationTests: XCTestCase {
    func testNewUserCanGrantAccessibilityAndEnableLaunchAtLogin() {
        let setupSnapshot = SetupSnapshot(
            hasCompletedSetup: false,
            hasPinnedDisplay: false,
            isPinnedDisplayAvailable: false,
            isAccessibilityTrusted: false
        )

        let presentation = SettingsPresentation.resolve(
            setupSnapshot: setupSnapshot,
            launchAtLoginStatus: .disabled
        )

        XCTAssertEqual(presentation.setupState, SetupState.resolve(setupSnapshot))
        XCTAssertEqual(presentation.accessibilityStatus, .needsInitialGrant)
        XCTAssertEqual(presentation.accessibilityAction, .requestPermission)
        XCTAssertEqual(presentation.launchAtLoginStatus, .disabled)
        XCTAssertEqual(presentation.launchAtLoginAction, .enable)
    }

    func testCompletedUserWithRevokedPermissionIsSentToSystemSettings() {
        let setupSnapshot = SetupSnapshot(
            hasCompletedSetup: true,
            hasPinnedDisplay: true,
            isPinnedDisplayAvailable: true,
            isAccessibilityTrusted: false
        )

        let presentation = SettingsPresentation.resolve(
            setupSnapshot: setupSnapshot,
            launchAtLoginStatus: .enabled
        )

        XCTAssertEqual(presentation.setupState.readiness, .needsAccessibilityPermission)
        XCTAssertEqual(presentation.accessibilityStatus, .needsRecovery)
        XCTAssertEqual(presentation.accessibilityAction, .openSystemSettings)
        XCTAssertEqual(presentation.launchAtLoginAction, .disable)
    }

    func testGrantedAccessibilityNeedsNoPermissionAction() {
        let presentation = SettingsPresentation.resolve(
            setupSnapshot: SetupSnapshot(
                hasCompletedSetup: true,
                hasPinnedDisplay: true,
                isPinnedDisplayAvailable: true,
                isAccessibilityTrusted: true
            ),
            launchAtLoginStatus: .disabled
        )

        XCTAssertEqual(presentation.accessibilityStatus, .granted)
        XCTAssertEqual(presentation.accessibilityAction, .none)
    }

    func testLaunchAtLoginApprovalAndUnavailableStatesAvoidInvalidToggle() {
        let setupSnapshot = SetupSnapshot(
            hasCompletedSetup: true,
            hasPinnedDisplay: true,
            isPinnedDisplayAvailable: true,
            isAccessibilityTrusted: true
        )

        let approval = SettingsPresentation.resolve(
            setupSnapshot: setupSnapshot,
            launchAtLoginStatus: .requiresApproval
        )
        let unavailable = SettingsPresentation.resolve(
            setupSnapshot: setupSnapshot,
            launchAtLoginStatus: .unavailable
        )

        XCTAssertEqual(approval.launchAtLoginAction, .openSystemSettings)
        XCTAssertEqual(unavailable.launchAtLoginAction, .none)
    }
}
