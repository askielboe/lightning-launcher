import Foundation

/// Learns per-prefix selection patterns to boost frequently chosen apps.
///
/// For each query prefix, tracks how often the user selects each app.
/// Example: if for prefix "ch" the user picks Chrome 9/10 times,
/// Chrome gets a strong boost when the query starts with "ch".
final class AdaptiveLearning {
    /// Selection counts per query prefix per bundle ID.
    /// Key: query prefix (2-4 chars), Value: [bundleId: count]
    private(set) var prefixTable: [String: [String: Int]] = [:]
    private let lock = NSLock()

    /// The maximum prefix length to track.
    private let maxPrefixLength = 4

    /// Records that the user selected a specific app for the given query.
    func recordSelection(bundleId: String, query: String) {
        lock.lock()
        defer { lock.unlock() }

        let prefixes = extractPrefixes(from: query)
        for prefix in prefixes {
            var counts = prefixTable[prefix, default: [:]]
            counts[bundleId, default: 0] += 1
            prefixTable[prefix] = counts
        }
    }

    /// Returns an adaptive boost for the given bundle ID and query.
    ///
    /// The boost is based on the selection frequency for matching prefixes.
    /// Returns 0.0 if no data is available.
    func boost(for bundleId: String, query: String) -> Double {
        lock.lock()
        defer { lock.unlock() }

        let prefixes = extractPrefixes(from: query)
        guard !prefixes.isEmpty else { return 0 }

        // Use the longest available prefix for the most specific signal
        for prefix in prefixes.reversed() {
            if let counts = prefixTable[prefix] {
                let total = counts.values.reduce(0, +)
                let count = counts[bundleId, default: 0]
                guard total > 0 else { continue }
                // Scale: max boost of 0.3 when the app is always selected for this prefix
                return Double(count) / Double(total) * 0.3
            }
        }

        return 0
    }

    /// Loads data from decoded persistence.
    func load(_ data: [String: [String: Int]]) {
        lock.lock()
        defer { lock.unlock() }
        prefixTable = data
    }

    /// Returns all data for persistence.
    func allData() -> [String: [String: Int]] {
        lock.lock()
        defer { lock.unlock() }
        return prefixTable
    }

    // MARK: - Private

    /// Extracts prefixes of length 2 through maxPrefixLength from the query.
    private func extractPrefixes(from query: String) -> [String] {
        let lower = query.lowercased()
        var prefixes: [String] = []
        for length in 2...maxPrefixLength {
            if lower.count >= length {
                prefixes.append(String(lower.prefix(length)))
            }
        }
        return prefixes
    }
}
