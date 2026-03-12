import Foundation

/// Full fuzzy matching algorithm with multiple match strategies.
///
/// Supports prefix, word-boundary initials, contiguous substring,
/// non-contiguous subsequence, and edit-distance (typo tolerance).
/// Each strategy produces a score reflecting match quality.
struct FuzzyMatcher {
    /// Result of a fuzzy match attempt.
    struct MatchResult {
        /// Score from 0.0 (no match) to 1.0 (perfect match).
        let score: Double

        /// Indices of matched characters in the target string (for highlighting).
        let matchedIndices: [Int]
    }

    /// Scores how well a query matches a target string.
    ///
    /// Tries multiple strategies in order of quality and returns the best match.
    func match(query: String, target: String) -> MatchResult {
        guard !query.isEmpty, !target.isEmpty else {
            return MatchResult(score: 0, matchedIndices: [])
        }
        return match(q: Array(query.lowercased()), t: Array(target.lowercased()))
    }

    /// Scores how well pre-lowercased character arrays match.
    ///
    /// Use this overload to avoid repeated lowercasing and array creation.
    func match(q: [Character], t: [Character]) -> MatchResult {
        guard !q.isEmpty, !t.isEmpty else {
            return MatchResult(score: 0, matchedIndices: [])
        }

        // 1. Exact prefix match — highest priority
        if let result = prefixMatch(q: q, t: t) {
            return result
        }

        // 2. Word-boundary match (initials)
        if let result = wordBoundaryMatch(q: q, t: t) {
            return result
        }

        // 3. Contiguous substring match
        if let result = substringMatch(q: q, t: t) {
            return result
        }

        // 4. Non-contiguous subsequence with scoring
        if let result = subsequenceMatch(q: q, t: t) {
            return result
        }

        // 5. Edit distance for typo tolerance (only for short queries)
        if q.count >= 3, let result = editDistanceMatch(q: q, t: t) {
            return result
        }

        return MatchResult(score: 0, matchedIndices: [])
    }

    // MARK: - Match Strategies

    private func prefixMatch(q: [Character], t: [Character]) -> MatchResult? {
        guard q.count <= t.count else { return nil }
        for i in q.indices {
            guard q[i] == t[i] else { return nil }
        }
        let indices = Array(0 ..< q.count)
        // Bonus for shorter targets (exact or near-exact match)
        let lengthBonus = Double(q.count) / Double(t.count) * 0.1
        return MatchResult(score: 0.9 + lengthBonus, matchedIndices: indices)
    }

    private func wordBoundaryMatch(q: [Character], t: [Character]) -> MatchResult? {
        // Find word boundary positions in target
        var boundaryIndices = [0] // First character is always a boundary
        for i in 1 ..< t.count where isWordBoundary(at: i, in: t) {
            boundaryIndices.append(i)
        }

        guard q.count <= boundaryIndices.count else { return nil }

        var matchedIndices: [Int] = []
        var qi = 0
        for bi in boundaryIndices {
            if qi < q.count, q[qi] == t[bi] {
                matchedIndices.append(bi)
                qi += 1
            }
        }

        guard qi == q.count else { return nil }

        // Score based on how many boundaries we matched vs total
        let score = 0.75 + (Double(q.count) / Double(boundaryIndices.count)) * 0.15
        return MatchResult(score: score, matchedIndices: matchedIndices)
    }

    private func substringMatch(q: [Character], t: [Character]) -> MatchResult? {
        guard q.count <= t.count else { return nil }
        for start in 0 ... (t.count - q.count) {
            let matches = (0 ..< q.count).allSatisfy { q[$0] == t[start + $0] }
            if matches {
                let indices = Array(start ..< (start + q.count))
                // Bonus for matching near the start
                let positionBonus = max(0, 0.1 - Double(start) * 0.01)
                return MatchResult(score: 0.6 + positionBonus, matchedIndices: indices)
            }
        }
        return nil
    }

    private func subsequenceMatch(q: [Character], t: [Character]) -> MatchResult? {
        var matchedIndices: [Int] = []
        var qi = 0
        var consecutiveBonus: Double = 0
        var lastMatchIndex = -2

        for ti in 0 ..< t.count {
            guard qi < q.count else { break }
            if q[qi] == t[ti] {
                matchedIndices.append(ti)
                if ti == lastMatchIndex + 1 {
                    consecutiveBonus += 0.05
                }
                lastMatchIndex = ti
                qi += 1
            }
        }

        guard qi == q.count else { return nil }

        // Base score + bonuses for consecutive chars and early positions
        let baseScore = 0.35
        let coverageBonus = Double(q.count) / Double(t.count) * 0.1
        let startBonus = matchedIndices.first == 0 ? 0.05 : 0
        let score = min(0.55, baseScore + consecutiveBonus + coverageBonus + startBonus)
        return MatchResult(score: score, matchedIndices: matchedIndices)
    }

    private func editDistanceMatch(q: [Character], t: [Character]) -> MatchResult? {
        // Only consider if lengths are somewhat similar
        guard abs(q.count - t.count) <= 2 else { return nil }

        // Check edit distance against each word in target
        let targetStr = String(t)
        let words = targetStr.split(separator: " ").map { Array($0) }

        for word in words {
            let dist = damerauLevenshtein(q, word)
            if dist <= 1 {
                return MatchResult(score: 0.45, matchedIndices: [])
            } else if dist <= 2, q.count >= 5 {
                return MatchResult(score: 0.3, matchedIndices: [])
            }
        }

        // Also check against full target
        let fullDist = damerauLevenshtein(q, t)
        if fullDist <= 1 {
            return MatchResult(score: 0.4, matchedIndices: [])
        }

        return nil
    }

    // MARK: - Helpers

    private func isWordBoundary(at index: Int, in chars: [Character]) -> Bool {
        let prev = chars[index - 1]
        let curr = chars[index]
        // Uppercase after lowercase (camelCase)
        if prev.isLowercase, curr.isUppercase { return true }
        // After a separator
        if !prev.isLetter, curr.isLetter { return true }
        return false
    }

    /// Computes the Damerau-Levenshtein distance between two character arrays.
    private func damerauLevenshtein(_ a: [Character], _ b: [Character]) -> Int {
        let m = a.count
        let n = b.count
        guard m > 0, n > 0 else { return max(m, n) }

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0 ... m {
            dp[i][0] = i
        }
        for j in 0 ... n {
            dp[0][j] = j
        }

        for i in 1 ... m {
            for j in 1 ... n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1, // deletion
                    dp[i][j - 1] + 1, // insertion
                    dp[i - 1][j - 1] + cost // substitution
                )
                // Transposition
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    dp[i][j] = min(dp[i][j], dp[i - 2][j - 2] + cost)
                }
            }
        }

        return dp[m][n]
    }
}
