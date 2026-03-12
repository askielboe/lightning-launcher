@testable import Lightning
import Foundation

/// Creates a minimal `AppEntry` for testing without needing real `.app` bundles.
func makeAppEntry(
    id: String,
    name: String,
    keywords: [String] = []
) -> AppEntry {
    let allKeywords = [name.lowercased()] + keywords.map { $0.lowercased() }
    // searchKeywords excludes the first element (full lowercased name) to match AppScanner behavior
    let searchKeywords = keywords.map { Array($0.lowercased()) }
    return AppEntry(
        id: id,
        name: name,
        path: URL(fileURLWithPath: "/Applications/\(name.replacingOccurrences(of: " ", with: "")).app"),
        keywords: allKeywords,
        searchName: Array(name.lowercased()),
        searchKeywords: searchKeywords
    )
}
