import XCTest
@testable import Lightning

final class FuzzyMatcherTests: XCTestCase {
    let matcher = FuzzyMatcher()

    func testExactPrefixMatch() {
        let result = matcher.match(query: "saf", target: "Safari")
        XCTAssertGreaterThan(result.score, 0.9)
        XCTAssertEqual(result.matchedIndices, [0, 1, 2])
    }

    func testFullNameMatch() {
        let result = matcher.match(query: "safari", target: "Safari")
        XCTAssertGreaterThan(result.score, 0.95)
    }

    func testWordBoundaryInitials() {
        let result = matcher.match(query: "vsc", target: "Visual Studio Code")
        XCTAssertGreaterThan(result.score, 0.7)
    }

    func testSubstringMatch() {
        let result = matcher.match(query: "studio", target: "Visual Studio Code")
        XCTAssertGreaterThan(result.score, 0.5)
    }

    func testSubsequenceMatch() {
        let result = matcher.match(query: "vsc", target: "Voice Scrambler")
        // "v" matches V, "s" matches S, "c" matches c in Scrambler
        let score = result.score
        XCTAssertGreaterThan(score, 0)
    }

    func testNoMatch() {
        let result = matcher.match(query: "xyz", target: "Safari")
        XCTAssertEqual(result.score, 0)
    }

    func testEmptyQuery() {
        let result = matcher.match(query: "", target: "Safari")
        XCTAssertEqual(result.score, 0)
    }

    func testEmptyTarget() {
        let result = matcher.match(query: "saf", target: "")
        XCTAssertEqual(result.score, 0)
    }

    func testCaseInsensitive() {
        let result = matcher.match(query: "SAFARI", target: "safari")
        XCTAssertGreaterThan(result.score, 0.9)
    }

    func testEditDistanceTypo() {
        let result = matcher.match(query: "sarafi", target: "Safari")
        XCTAssertGreaterThan(result.score, 0)
    }

    func testPrefixScoresHigherThanSubstring() {
        let prefix = matcher.match(query: "ch", target: "Chrome")
        let substring = matcher.match(query: "ro", target: "Chrome")
        XCTAssertGreaterThan(prefix.score, substring.score)
    }
}
