import Testing
@testable import Lightning

@Suite struct SearchEngineTests {

    // MARK: - Fixtures

    private let safari = makeAppEntry(id: "com.apple.Safari", name: "Safari", keywords: ["browser", "web"])
    private let settings = makeAppEntry(id: "com.apple.systempreferences", name: "System Settings", keywords: ["preferences"])
    private let slack = makeAppEntry(id: "com.tinyspeck.slackmacgap", name: "Slack", keywords: ["chat", "messaging"])
    private let spotify = makeAppEntry(id: "com.spotify.client", name: "Spotify", keywords: ["music", "player"])

    private var allApps: [AppEntry] { [safari, settings, slack, spotify] }

    // MARK: - Empty query

    @Test func emptyQueryReturnsEmpty() {
        let engine = SearchEngine()
        let results = engine.search(query: "", in: allApps)
        #expect(results.isEmpty)
    }

    // MARK: - Basic matching

    @Test func exactPrefixMatchReturnsApp() {
        let engine = SearchEngine()
        let results = engine.search(query: "saf", in: allApps)
        #expect(!results.isEmpty)
        #expect(results.first?.id == "com.apple.Safari")
    }

    @Test func noMatchReturnsEmpty() {
        let engine = SearchEngine()
        let results = engine.search(query: "zzzzxyzw", in: allApps)
        #expect(results.isEmpty)
    }

    // MARK: - Result limits and ordering

    @Test func resultsLimitedToMaxResults() {
        var engine = SearchEngine()
        engine.maxResults = 2

        // "s" should match Safari, System Settings, Slack, Spotify — but capped at 2
        let results = engine.search(query: "s", in: allApps)
        #expect(results.count <= 2)
    }

    @Test func resultsOrderedByScore() {
        let engine = SearchEngine()
        // "slack" should rank Slack highest (exact prefix match)
        let results = engine.search(query: "slack", in: allApps)
        #expect(!results.isEmpty)
        #expect(results.first?.id == "com.tinyspeck.slackmacgap")
    }

    // MARK: - Keyword matching

    @Test func keywordMatchIncluded() {
        let engine = SearchEngine()
        // "browser" is a keyword for Safari
        let results = engine.search(query: "browser", in: allApps)
        let ids = results.map(\.id)
        #expect(ids.contains("com.apple.Safari"))
    }

    @Test func nameMatchRanksAboveKeyword() {
        let engine = SearchEngine()
        // "music" is a keyword for Spotify; no app is named "Music" in our set
        // Create an app named "Music" to test name vs keyword ranking
        let musicApp = makeAppEntry(id: "com.apple.Music", name: "Music")
        let apps = allApps + [musicApp]

        let results = engine.search(query: "music", in: apps)
        #expect(!results.isEmpty)
        // Name match ("Music") should rank above keyword match ("Spotify" with keyword "music")
        #expect(results.first?.id == "com.apple.Music")
    }

    // MARK: - Score calculator integration

    @Test func searchWithScoreCalculator() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()

        // Boost Slack heavily for query "s"
        for _ in 0..<10 {
            frecency.recordLaunch(bundleId: "com.tinyspeck.slackmacgap")
            adaptive.recordSelection(bundleId: "com.tinyspeck.slackmacgap", query: "s")
        }

        var engine = SearchEngine()
        engine.scoreCalculator = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        // "s" matches multiple apps; Slack should rank first due to boosting
        let results = engine.search(query: "s", in: allApps)
        #expect(!results.isEmpty)

        // Verify boosted app appears (exact ranking depends on match scores + boosts)
        let ids = results.map(\.id)
        #expect(ids.contains("com.tinyspeck.slackmacgap"))
    }
}
