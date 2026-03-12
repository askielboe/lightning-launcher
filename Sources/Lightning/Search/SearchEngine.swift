import Foundation

/// Orchestrates search matching and ranking across the app index.
///
/// Takes a query string, scores all indexed apps using fuzzy matching
/// combined with frecency and adaptive learning, and returns the top
/// results sorted by relevance.
struct SearchEngine {
    /// Maximum number of results to return.
    var maxResults: Int = 8

    private let fuzzyMatcher = FuzzyMatcher()

    /// Optional score calculator for frecency + adaptive boosting.
    var scoreCalculator: ScoreCalculator?

    /// Searches the index for apps matching the query.
    ///
    /// - Parameters:
    ///   - query: The user's search string.
    ///   - entries: All indexed app entries to search through.
    /// - Returns: Top matching entries sorted by score (descending).
    func search(query: String, in entries: [AppEntry]) -> [AppEntry] {
        guard !query.isEmpty else { return [] }

        // Convert query to lowercased character array once
        let q = Array(query.lowercased())

        // Snapshot ranking data once before the loop
        let frecencySnapshot = scoreCalculator?.frecencyTracker.snapshot()
        let adaptiveSnapshot = scoreCalculator?.adaptiveLearning.snapshot()
        let prefixes = scoreCalculator?.adaptiveLearning.extractPrefixes(from: query) ?? []

        var scored: [(entry: AppEntry, score: Double)] = []

        for entry in entries {
            // Match against the pre-computed lowercased name
            let nameResult = fuzzyMatcher.match(q: q, t: entry.searchName)
            var bestScore = nameResult.score

            // Also try matching against pre-computed keyword arrays
            for keyword in entry.searchKeywords {
                let keywordResult = fuzzyMatcher.match(q: q, t: keyword)
                let adjustedScore = keywordResult.score * 0.85
                bestScore = max(bestScore, adjustedScore)
            }

            if bestScore > 0 {
                let finalScore: Double
                if let calc = scoreCalculator,
                   let fSnap = frecencySnapshot,
                   let aSnap = adaptiveSnapshot {
                    finalScore = calc.finalScore(
                        matchScore: bestScore,
                        bundleId: entry.id,
                        prefixes: prefixes,
                        frecencySnapshot: fSnap,
                        adaptiveSnapshot: aSnap
                    )
                } else {
                    finalScore = bestScore
                }
                scored.append((entry, finalScore))
            }
        }

        scored.sort { $0.score > $1.score }
        return Array(scored.prefix(maxResults).map(\.entry))
    }
}
