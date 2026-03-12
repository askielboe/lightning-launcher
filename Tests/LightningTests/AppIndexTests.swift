import Foundation
import Testing
@testable import Lightning

@Suite struct AppIndexTests {

    // MARK: - Empty state

    @Test func emptyIndexReturnsNoEntries() {
        let index = AppIndex()
        #expect(index.allEntries.isEmpty)
    }

    // MARK: - Update and retrieval

    @Test func updateAddsEntries() {
        let index = AppIndex()
        let entries = [
            makeAppEntry(id: "com.apple.Safari", name: "Safari"),
            makeAppEntry(id: "com.apple.Mail", name: "Mail"),
        ]
        index.update(with: entries)
        #expect(index.allEntries.count == 2)
    }

    @Test func entryLookupByBundleId() {
        let index = AppIndex()
        let entries = [
            makeAppEntry(id: "com.apple.Safari", name: "Safari"),
            makeAppEntry(id: "com.apple.Mail", name: "Mail"),
        ]
        index.update(with: entries)

        let safari = index.entry(forBundleId: "com.apple.Safari")
        #expect(safari != nil)
        #expect(safari?.name == "Safari")

        let missing = index.entry(forBundleId: "com.nonexistent.app")
        #expect(missing == nil)
    }

    // MARK: - Merge behavior

    @Test func updatePreservesUsageStats() {
        let index = AppIndex()

        // Initial scan
        var entry = makeAppEntry(id: "com.apple.Safari", name: "Safari")
        entry.frecencyScore = 5.0
        entry.launchCount = 3
        entry.lastLaunched = Date(timeIntervalSince1970: 1000)
        index.update(with: [entry])

        // Simulate a re-scan with a fresh entry (no usage stats)
        let freshEntry = makeAppEntry(id: "com.apple.Safari", name: "Safari")
        index.update(with: [freshEntry])

        let result = index.entry(forBundleId: "com.apple.Safari")
        #expect(result != nil)
        #expect(abs(result!.frecencyScore - 5.0) < 0.001)
        #expect(result?.launchCount == 3)
        #expect(result?.lastLaunched == Date(timeIntervalSince1970: 1000))
    }

    @Test func updateRemovesStaleEntries() {
        let index = AppIndex()
        index.update(with: [
            makeAppEntry(id: "com.apple.Safari", name: "Safari"),
            makeAppEntry(id: "com.apple.Mail", name: "Mail"),
        ])
        #expect(index.allEntries.count == 2)

        // Re-scan with only Safari — Mail should be dropped
        index.update(with: [
            makeAppEntry(id: "com.apple.Safari", name: "Safari"),
        ])
        #expect(index.allEntries.count == 1)
        #expect(index.entry(forBundleId: "com.apple.Mail") == nil)
    }

    // MARK: - Record launch

    @Test func recordLaunchIncrementsCount() {
        let index = AppIndex()
        index.update(with: [makeAppEntry(id: "com.apple.Safari", name: "Safari")])

        let before = index.entry(forBundleId: "com.apple.Safari")
        #expect(before?.launchCount == 0)
        #expect(before?.lastLaunched == nil)

        index.recordLaunch(forBundleId: "com.apple.Safari")

        let after = index.entry(forBundleId: "com.apple.Safari")
        #expect(after?.launchCount == 1)
        #expect(after?.lastLaunched != nil)
    }

    // MARK: - Cache invalidation

    @Test func cacheInvalidatedOnUpdate() {
        let index = AppIndex()
        index.update(with: [makeAppEntry(id: "com.apple.Safari", name: "Safari")])
        #expect(index.allEntries.count == 1)

        // Second update adds another entry — cache must reflect the change
        index.update(with: [
            makeAppEntry(id: "com.apple.Safari", name: "Safari"),
            makeAppEntry(id: "com.apple.Mail", name: "Mail"),
        ])
        #expect(index.allEntries.count == 2)
    }
}
