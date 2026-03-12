import Testing
@testable import Lightning

@Suite struct FrecencyTrackerTests {
    @Test func initialMultiplierIsNeutral() {
        let tracker = FrecencyTracker()
        let multiplier = tracker.multiplier(for: "com.test.app")
        #expect(multiplier == 1.0)
    }

    @Test func singleLaunchIncreasesMultiplier() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app")
        let multiplier = tracker.multiplier(for: "com.test.app")
        #expect(multiplier > 1.0)
    }

    @Test func multipleLaunchesIncreaseMultiplier() {
        let tracker = FrecencyTracker()
        for _ in 0..<5 {
            tracker.recordLaunch(bundleId: "com.test.app")
        }
        let multiplier = tracker.multiplier(for: "com.test.app")
        #expect(multiplier > 1.0)
    }

    @Test func multiplierCapsAt2() {
        let tracker = FrecencyTracker()
        for _ in 0..<100 {
            tracker.recordLaunch(bundleId: "com.test.app")
        }
        let multiplier = tracker.multiplier(for: "com.test.app")
        #expect(multiplier <= 2.0)
    }

    @Test func differentAppsTrackedSeparately() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app1")
        let m1 = tracker.multiplier(for: "com.test.app1")
        let m2 = tracker.multiplier(for: "com.test.app2")
        #expect(m1 > m2)
    }

    @Test func recordsSerialization() {
        let tracker = FrecencyTracker()
        tracker.recordLaunch(bundleId: "com.test.app")
        let records = tracker.allRecords()
        #expect(records["com.test.app"] != nil)

        let tracker2 = FrecencyTracker()
        tracker2.load(records)
        #expect(tracker2.multiplier(for: "com.test.app") > 1.0)
    }
}
