import SwiftUI

/// A single row in the search results list.
struct ResultRow: View {
    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            switch result {
            case let .app(entry):
                appIcon(entry)
                Text(entry.name)
                    .font(.system(size: 16))
                    .lineLimit(1)

            case let .calculation(value):
                Image(systemName: "equal.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
                Text("= \(value)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.3))
                : nil
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func appIcon(_ entry: AppEntry) -> some View {
        if let icon = entry.icon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 32, height: 32)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.secondary)
        }
    }
}
