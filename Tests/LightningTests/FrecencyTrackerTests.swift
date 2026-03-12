import XCTest
@testable import Lightning

final class FrecencyTrackerTests: XCTestCase {
    func testInitialMultiplierIsNeutral() {
        let tracker = FrecencyTracker()
        let multiplier = tracker.multiplier(for: "com.test.app")
        XCTAssertEqual(multiplier, 1.0)
    }

    func testSingleLaunchIncreasesMultiplier() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app")
        let multiplier = tracker.multiplier(for: "com.test.app")
        XCTAssertGreaterThan(multiplier, 1.0)
    }

    func testMultipleLaunchesIncreaseMultiplier() {
        let tracker = FrecencyTracker()
        for _ in 0..<5 {
            tracker.recordLaunch(bundleId: "com.test.app")
        }
        let multiplier = tracker.multiplier(for: "com.test.app")
        XCTAssertGreaterThan(multiplier, 1.0)
    }

    func testMultiplierCapsAt2() {
        let tracker = FrecencyTracker()
        for _ in 0..<100 {
            tracker.recordLaunch(bundleId: "com.test.app")
        }
        let multiplier = tracker.multiplier(for: "com.test.app")
        XCTAssertLessThanOrEqual(multiplier, 2.0)
    }

    func testDifferentAppsTrackedSeparately() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app1")
        let m1 = tracker.multiplier(for: "com.test.app1")
        let m2 = tracker.multiplier(for: "com.test.app2")
        XCTAssertGreaterThan(m1, m2)
    }

    func testRecordsSerialization() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app")
        let records = tracker.allRecords()
        XCTAssertNotNil(records["com.test.app"])

        let tracker2 = FrecencyTracker()
        tracker2.load(records)
        XCTAssertGreaterThan(tracker2.multiplier(for: "com.test.app"), 1.0)
    }
}
