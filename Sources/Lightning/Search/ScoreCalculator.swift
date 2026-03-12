import Foundation

/// Combines match score with frecency and adaptive boost for final ranking.
///
/// Final score = matchScore * frecencyMultiplier + adaptiveBoost
struct ScoreCalculator {
    let frecencyTracker: FrecencyTracker
    let adaptiveLearning: AdaptiveLearning

    /// Calculates the final score for an app entry given the query and match score.
    ///
    /// - Parameters:
    ///   - matchScore: Raw score from the fuzzy matcher (0.0 to 1.0).
    ///   - bundleId: The app's bundle identifier.
    ///   - query: The user's search query (for adaptive learning lookup).
    /// - Returns: Combined score incorporating frecency and adaptive learning.
    func finalScore(matchScore: Double, bundleId: String, query: String) -> Double {
        let frecencyMultiplier = frecencyTracker.multiplier(for: bundleId)
        let adaptiveBoost = adaptiveLearning.boost(for: bundleId, query: query)
        return matchScore * frecencyMultiplier + adaptiveBoost
    }
}
