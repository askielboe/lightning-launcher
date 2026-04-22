/// A single item in the search results list.
///
/// Wraps either a matched application or an arithmetic evaluation result.
enum SearchResult: Identifiable {
    case app(AppEntry)
    case calculation(result: String)

    var id: String {
        switch self {
        case let .app(entry): entry.id
        case .calculation: "lightning.calculation"
        }
    }
}
