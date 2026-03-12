import AppKit

/// Actor-based async icon cache for application icons.
///
/// Loads and caches app icons at 32x32 resolution. Thread-safe by design
/// via Swift's actor model.
actor IconCache {
    private var cache: [String: NSImage] = [:]

    /// The standard icon size used throughout the UI.
    static let iconSize = NSSize(width: 32, height: 32)

    /// Returns the cached icon for the given bundle ID, or loads it from disk.
    func icon(for entry: AppEntry) -> NSImage {
        if let cached = cache[entry.id] {
            return cached
        }
        let image = loadIcon(for: entry)
        cache[entry.id] = image
        return image
    }

    /// Preloads icons for all provided entries.
    func preload(entries: [AppEntry]) {
        for entry in entries {
            if cache[entry.id] == nil {
                cache[entry.id] = loadIcon(for: entry)
            }
        }
    }

    /// Clears the entire cache.
    func clear() {
        cache.removeAll()
    }

    // MARK: - Private

    private func loadIcon(for entry: AppEntry) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: entry.path.path)
        icon.size = Self.iconSize
        return icon
    }
}
