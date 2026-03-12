import XCTest
@testable import Lightning

final class AppScannerTests: XCTestCase {
    let scanner = AppScanner()

    func testTokenizeSimpleName() {
        let tokens = scanner.tokenize("Safari")
        XCTAssertTrue(tokens.contains("safari"))
    }

    func testTokenizeMultiWord() {
        let tokens = scanner.tokenize("Visual Studio Code")
        XCTAssertTrue(tokens.contains("visual"))
        XCTAssertTrue(tokens.contains("studio"))
        XCTAssertTrue(tokens.contains("code"))
    }

    func testTokenizeCamelCase() {
        let tokens = scanner.tokenize("WebStorm")
        XCTAssertTrue(tokens.contains("web"))
        XCTAssertTrue(tokens.contains("storm"))
    }

    func testTokenizeWithHyphen() {
        let tokens = scanner.tokenize("Hex-Editor")
        XCTAssertTrue(tokens.contains("hex"))
        XCTAssertTrue(tokens.contains("editor"))
    }

    func testTokenizeWithDot() {
        let tokens = scanner.tokenize("com.app.name")
        XCTAssertTrue(tokens.contains("com"))
        XCTAssertTrue(tokens.contains("app"))
        XCTAssertTrue(tokens.contains("name"))
    }

    func testTokenizeIncludesFullName() {
        let tokens = scanner.tokenize("Visual Studio Code")
        XCTAssertEqual(tokens.first, "visual studio code")
    }

    func testScanFindsSystemApps() {
        // Integration test: should find at least some apps
        let entries = scanner.scan()
        XCTAssertGreaterThan(entries.count, 0)
    }
}
