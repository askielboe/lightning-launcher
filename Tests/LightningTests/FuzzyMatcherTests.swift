@testable import Lightning
import Testing

struct FuzzyMatcherTests {
    let matcher = FuzzyMatcher()

    @Test func exactPrefixMatch() {
        let result = matcher.match(query: "saf", target: "Safari")
        #expect(result.score > 0.9)
        #expect(result.matchedIndices == [0, 1, 2])
    }

    @Test func fullNameMatch() {
        let result = matcher.match(query: "safari", target: "Safari")
        #expect(result.score > 0.95)
    }

    @Test func wordBoundaryInitials() {
        let result = matcher.match(query: "vsc", target: "Visual Studio Code")
        #expect(result.score > 0.7)
    }

    @Test func substringMatch() {
        let result = matcher.match(query: "studio", target: "Visual Studio Code")
        #expect(result.score > 0.5)
    }

    @Test func subsequenceMatch() {
        let result = matcher.match(query: "vsc", target: "Voice Scrambler")
        // "v" matches V, "s" matches S, "c" matches c in Scrambler
        let score = result.score
        #expect(score > 0)
    }

    @Test func noMatch() {
        let result = matcher.match(query: "xyz", target: "Safari")
        #expect(result.score == 0)
    }

    @Test func emptyQuery() {
        let result = matcher.match(query: "", target: "Safari")
        #expect(result.score == 0)
    }

    @Test func emptyTarget() {
        let result = matcher.match(query: "saf", target: "")
        #expect(result.score == 0)
    }

    @Test func caseInsensitive() {
        let result = matcher.match(query: "SAFARI", target: "safari")
        #expect(result.score > 0.9)
    }

    @Test func editDistanceTypo() {
        let result = matcher.match(query: "sarafi", target: "Safari")
        #expect(result.score > 0)
    }

    @Test func prefixScoresHigherThanSubstring() {
        let prefix = matcher.match(query: "ch", target: "Chrome")
        let substring = matcher.match(query: "ro", target: "Chrome")
        #expect(prefix.score > substring.score)
    }
}
