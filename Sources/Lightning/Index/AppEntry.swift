import AppKit

/// Represents a discovered application in the index.
///
/// Stores the app's metadata, icon, search keywords, and usage statistics
/// for ranking purposes.
struct AppEntry: Identifiable {
    /// Unique identifier — the app's bundle identifier (e.g., "com.apple.Safari").
    let id: String

    /// Display name of the application.
    let name: String

    /// File URL to the `.app` bundle on disk.
    let path: URL

    /// Cached app icon (loaded asynchronously).
    var icon: NSImage?

    /// Tokenized search keywords derived from the app name.
    let keywords: [String]

    /// Frecency score for ranking (updated on launch).
    var frecencyScore: Double = 0.0

    /// Timestamp of last launch via Lightning.
    var lastLaunched: Date?

    /// Number of times launched via Lightning.
    var launchCount: Int = 0
}

extension AppEntry: Equatable {
    static func == (lhs: AppEntry, rhs: AppEntry) -> Bool {
        lhs.id == rhs.id && lhs.path == rhs.path
    }
}

extension AppEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
