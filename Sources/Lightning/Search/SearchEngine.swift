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

        var scored: [(entry: AppEntry, score: Double)] = []

        for entry in entries {
            // Match against the full app name
            let nameResult = fuzzyMatcher.match(query: query, target: entry.name)
            var bestScore = nameResult.score

            // Also try matching against individual keywords
            for keyword in entry.keywords.dropFirst() {
                let keywordResult = fuzzyMatcher.match(query: query, target: keyword)
                // Keyword matches are slightly discounted
                let adjustedScore = keywordResult.score * 0.85
                bestScore = max(bestScore, adjustedScore)
            }

            if bestScore > 0 {
                // Apply frecency and adaptive boosting if available
                let finalScore: Double
                if let calc = scoreCalculator {
                    finalScore = calc.finalScore(
                        matchScore: bestScore,
                        bundleId: entry.id,
                        query: query
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
