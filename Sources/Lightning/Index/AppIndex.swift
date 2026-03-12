import Foundation

/// Thread-safe in-memory index of discovered applications.
///
/// Backed by a dictionary keyed on bundle ID. Uses `NSLock` for
/// thread safety across the main thread and background scan queues.
final class AppIndex {
    private var entries: [String: AppEntry] = [:]
    private var cachedEntries: [AppEntry]?
    private let lock = NSLock()

    /// Returns all indexed app entries (cached to avoid repeated Array creation).
    var allEntries: [AppEntry] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedEntries { return cached }
        let array = Array(entries.values)
        cachedEntries = array
        return array
    }

    /// Returns the entry for a specific bundle ID, if present.
    func entry(forBundleId id: String) -> AppEntry? {
        lock.lock()
        defer { lock.unlock() }
        return entries[id]
    }

    /// Updates the index with freshly scanned entries.
    ///
    /// Merges new entries while preserving frecency scores and launch
    /// statistics from existing entries.
    func update(with scannedEntries: [AppEntry]) {
        lock.lock()
        defer { lock.unlock() }

        var newIndex: [String: AppEntry] = [:]
        for var entry in scannedEntries {
            if let existing = entries[entry.id] {
                // Preserve usage stats from existing entry
                entry.frecencyScore = existing.frecencyScore
                entry.lastLaunched = existing.lastLaunched
                entry.launchCount = existing.launchCount
                entry.icon = existing.icon
            }
            newIndex[entry.id] = entry
        }
        entries = newIndex
        cachedEntries = nil
    }

    /// Updates the icon for a specific app entry.
    func updateIcon(forBundleId id: String, icon: NSImage) {
        lock.lock()
        defer { lock.unlock() }
        entries[id]?.icon = icon
        cachedEntries = nil
    }

    /// Records a launch for the given bundle ID.
    func recordLaunch(forBundleId id: String) {
        lock.lock()
        defer { lock.unlock() }
        entries[id]?.launchCount += 1
        entries[id]?.lastLaunched = Date()
        cachedEntries = nil
    }
}

import AppKit
