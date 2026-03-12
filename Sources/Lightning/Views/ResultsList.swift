import SwiftUI

/// Displays the list of search results with keyboard navigation.
///
/// Shows up to 8 results. Arrow keys move selection, Return launches
/// the selected app.
struct ResultsList: View {
    let results: [AppEntry]
    let selectedIndex: Int
    let onSelect: (AppEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, entry in
                ResultRow(entry: entry, isSelected: index == selectedIndex)
                    .onTapGesture {
                        onSelect(entry)
                    }
            }
        }
    }
}
