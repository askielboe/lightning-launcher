@testable import Lightning
import Testing

struct ScoreCalculatorTests {
    // MARK: - Base score

    @Test func baseScoreWithNoRankingData() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()
        let calc = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        // With no history: multiplier = 1.0, boost = 0.0 → finalScore == matchScore
        let score = calc.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        #expect(abs(score - 0.8) < 0.001)
    }

    // MARK: - Frecency multiplier

    @Test func frecencyMultiplierApplied() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()
        let calc = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        // Record several launches to build up frecency
        for _ in 0 ..< 5 {
            frecency.recordLaunch(bundleId: "com.test.app")
        }

        let score = calc.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        // Frecency multiplier > 1.0 after launches, so score > 0.8
        #expect(score > 0.8)
    }

    // MARK: - Adaptive boost

    @Test func adaptiveBoostApplied() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()
        let calc = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        // Record selections for a query to build adaptive boost
        for _ in 0 ..< 5 {
            adaptive.recordSelection(bundleId: "com.test.app", query: "test")
        }

        let score = calc.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        // Adaptive boost > 0 after selections, so score > matchScore * 1.0
        #expect(score > 0.8)
    }

    // MARK: - Combined

    @Test func combinedFrecencyAndAdaptive() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()
        let calc = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        for _ in 0 ..< 5 {
            frecency.recordLaunch(bundleId: "com.test.app")
            adaptive.recordSelection(bundleId: "com.test.app", query: "test")
        }

        let combined = calc.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        // Both effects active: score should exceed either alone
        let frecencyOnly: Double = {
            let f = FrecencyTracker()
            for _ in 0 ..< 5 {
                f.recordLaunch(bundleId: "com.test.app")
            }
            let c = ScoreCalculator(frecencyTracker: f, adaptiveLearning: AdaptiveLearning())
            return c.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        }()
        let adaptiveOnly: Double = {
            let a = AdaptiveLearning()
            for _ in 0 ..< 5 {
                a.recordSelection(bundleId: "com.test.app", query: "test")
            }
            let c = ScoreCalculator(frecencyTracker: FrecencyTracker(), adaptiveLearning: a)
            return c.finalScore(matchScore: 0.8, bundleId: "com.test.app", query: "test")
        }()

        #expect(combined > frecencyOnly)
        #expect(combined > adaptiveOnly)
    }

    // MARK: - Snapshot variant

    @Test func snapshotVariantMatchesLockVariant() {
        let frecency = FrecencyTracker()
        let adaptive = AdaptiveLearning()
        let calc = ScoreCalculator(frecencyTracker: frecency, adaptiveLearning: adaptive)

        for _ in 0 ..< 3 {
            frecency.recordLaunch(bundleId: "com.test.app")
            adaptive.recordSelection(bundleId: "com.test.app", query: "test")
        }

        let lockScore = calc.finalScore(matchScore: 0.75, bundleId: "com.test.app", query: "test")

        let frecencySnap = frecency.snapshot()
        let adaptiveSnap = adaptive.snapshot()
        let prefixes = adaptive.extractPrefixes(from: "test")
        let snapScore = calc.finalScore(
            matchScore: 0.75,
            bundleId: "com.test.app",
            prefixes: prefixes,
            frecencySnapshot: frecencySnap,
            adaptiveSnapshot: adaptiveSnap
        )

        #expect(abs(lockScore - snapScore) < 0.0001)
    }
}
