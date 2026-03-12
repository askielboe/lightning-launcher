import Foundation

/// Tracks app launch frequency with exponential time decay.
///
/// Uses the formula: `score = score * e^(-λ*Δt) + 1.0` on each launch,
/// where λ = ln(2) / halfLife. Apps used recently and frequently score higher.
final class FrecencyTracker {
    /// A single frecency record for an app.
    struct Record: Codable {
        var score: Double
        var lastAccess: Date
    }

    /// Half-life for the exponential decay, in seconds.
    /// Default is 7 days.
    private let halfLife: TimeInterval = 7 * 24 * 3600

    /// Decay constant: λ = ln(2) / halfLife
    private var lambda: Double {
        log(2.0) / halfLife
    }

    /// Per-bundle-ID frecency records.
    private(set) var records: [String: Record] = [:]
    private let lock = NSLock()

    /// Records a launch event for the given bundle ID.
    func recordLaunch(bundleId: String) {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if var record = records[bundleId] {
            let dt = now.timeIntervalSince(record.lastAccess)
            record.score = record.score * exp(-lambda * dt) + 1.0
            record.lastAccess = now
            records[bundleId] = record
        } else {
            records[bundleId] = Record(score: 1.0, lastAccess: now)
        }
    }

    /// Returns a frecency multiplier (0.5 to 2.0) for the given bundle ID.
    ///
    /// Apps with no history get 1.0 (neutral). Frequently used apps get up to 2.0.
    func multiplier(for bundleId: String) -> Double {
        lock.lock()
        defer { lock.unlock() }

        guard let record = records[bundleId] else { return 1.0 }

        let dt = Date().timeIntervalSince(record.lastAccess)
        let decayed = record.score * exp(-lambda * dt)

        // Map decayed score to a multiplier in [0.5, 2.0]
        // score of 0 → 1.0x (neutral), score of ~5+ → 2.0x
        return min(2.0, max(0.5, 1.0 + decayed * 0.2))
    }

    /// Returns a snapshot of all records, locking once.
    ///
    /// Use this to avoid per-entry lock acquisition during search scoring.
    func snapshot() -> [String: Record] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }

    /// Returns a frecency multiplier using a pre-fetched snapshot (lock-free).
    func multiplier(for bundleId: String, in snapshot: [String: Record]) -> Double {
        guard let record = snapshot[bundleId] else { return 1.0 }

        let dt = Date().timeIntervalSince(record.lastAccess)
        let decayed = record.score * exp(-lambda * dt)

        return min(2.0, max(0.5, 1.0 + decayed * 0.2))
    }

    /// Loads records from decoded data.
    func load(_ data: [String: Record]) {
        lock.lock()
        defer { lock.unlock() }
        records = data
    }

    /// Returns all records for persistence.
    func allRecords() -> [String: Record] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }
}
