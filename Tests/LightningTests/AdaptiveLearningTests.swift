import XCTest
@testable import Lightning

final class AdaptiveLearningTests: XCTestCase {
    func testNoDataReturnsZeroBoost() {
        let learner = AdaptiveLearning()
        let boost = learner.boost(for: "com.google.Chrome", query: "ch")
        XCTAssertEqual(boost, 0)
    }

    func testSingleSelectionGivesBoost() {
        let learner = AdaptiveLearning()
        learner.recordSelection(bundleId: "com.google.Chrome", query: "ch")
        let boost = learner.boost(for: "com.google.Chrome", query: "ch")
        XCTAssertGreaterThan(boost, 0)
    }

    func testFrequentSelectionGivesHigherBoost() {
        let learner = AdaptiveLearning()
        // Select Chrome 9 times for "ch"
        for _ in 0..<9 {
            learner.recordSelection(bundleId: "com.google.Chrome", query: "ch")
        }
        // Select Chess once for "ch"
        learner.recordSelection(bundleId: "com.apple.Chess", query: "ch")

        let chromeBoost = learner.boost(for: "com.google.Chrome", query: "ch")
        let chessBoost = learner.boost(for: "com.apple.Chess", query: "ch")
        XCTAssertGreaterThan(chromeBoost, chessBoost)
    }

    func testDifferentPrefixesTrackedSeparately() {
        let learner = AdaptiveLearning()
        learner.recordSelection(bundleId: "com.google.Chrome", query: "ch")
        learner.recordSelection(bundleId: "com.apple.Safari", query: "sa")

        let chromeForCh = learner.boost(for: "com.google.Chrome", query: "ch")
        let chromeForSa = learner.boost(for: "com.google.Chrome", query: "sa")
        XCTAssertGreaterThan(chromeForCh, chromeForSa)
    }

    func testShortQueryReturnsZero() {
        let learner = AdaptiveLearning()
        learner.recordSelection(bundleId: "com.test.app", query: "a")
        let boost = learner.boost(for: "com.test.app", query: "a")
        XCTAssertEqual(boost, 0) // Single char query doesn't generate prefixes
    }

    func testDataPersistence() {
        let learner = AdaptiveLearning()
        learner.recordSelection(bundleId: "com.google.Chrome", query: "ch")
        let data = learner.allData()

        let learner2 = AdaptiveLearning()
        learner2.load(data)
        let boost = learner2.boost(for: "com.google.Chrome", query: "ch")
        XCTAssertGreaterThan(boost, 0)
    }
}
