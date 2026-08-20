import XCTest

@testable import Berth

final class AppLanguageTests: XCTestCase {
    func testSupportedLanguageNamesUseEachLanguageSelfName() {
        XCTAssertEqual(AppLanguage.displayName(for: "en"), "English")
        XCTAssertEqual(AppLanguage.displayName(for: "zh-TW"), "繁體中文（台灣）")
    }
}
