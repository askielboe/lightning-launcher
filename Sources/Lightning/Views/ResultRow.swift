import SwiftUI

/// A single row in the search results list showing an app icon and name.
struct ResultRow: View {
    let entry: AppEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
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

            Text(entry.name)
                .font(.system(size: 16))
                .lineLimit(1)

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
}
