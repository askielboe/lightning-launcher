import SwiftUI

/// Displays the list of search results with keyboard navigation.
///
/// Shows up to 8 results. Arrow keys move selection, Return launches
/// the selected app or copies a calculation result.
struct ResultsList: View {
    let results: [SearchResult]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                ResultRow(result: result, isSelected: index == selectedIndex)
                    .onTapGesture {
                        onSelect(index)
                    }
            }
        }
    }
}
