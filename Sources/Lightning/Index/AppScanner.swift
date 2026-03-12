import AppKit
import Foundation

/// Scans the filesystem for `.app` bundles and produces `AppEntry` values.
///
/// Enumerates standard macOS application directories plus user-configurable
/// paths. Reads bundle metadata for each discovered app.
struct AppScanner {
    /// The directories to scan for applications.
    static var defaultSearchPaths: [URL] {
        var paths = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Cryptexes/App/System/Applications")
        ]
        // ~/Applications
        if let home = FileManager.default.homeDirectoryForCurrentUser as URL? {
            paths.append(home.appendingPathComponent("Applications"))
        }
        return paths
    }

    /// Default search paths minus any the user has removed.
    static var activeDefaultPaths: [URL] {
        let removed = Set(UserPreferences.shared.removedDefaultPaths)
        return defaultSearchPaths.filter { !removed.contains($0.path) }
    }

    /// Scans all configured directories and returns discovered app entries.
    ///
    /// - Parameter additionalPaths: Extra directories to include beyond the defaults.
    /// - Returns: Array of discovered `AppEntry` values.
    func scan(additionalPaths: [URL] = []) -> [AppEntry] {
        let allPaths = Self.activeDefaultPaths + additionalPaths
        var entries: [String: AppEntry] = [:]

        for directory in allPaths {
            let apps = scanDirectory(directory)
            for app in apps where entries[app.id] == nil {
                // First discovered path wins (earlier directories have priority)
                entries[app.id] = app
            }
        }

        return Array(entries.values)
    }

    // MARK: - Private

    private func scanDirectory(_ directory: URL) -> [AppEntry] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var entries: [AppEntry] = []

        for url in contents {
            if url.pathExtension == "app" {
                if let entry = makeEntry(from: url) {
                    entries.append(entry)
                }
            } else if url.hasDirectoryPath {
                // Recurse one level into subdirectories (e.g., /Applications/Utilities/)
                let subEntries = scanDirectory(url)
                entries.append(contentsOf: subEntries)
            }
        }

        return entries
    }

    private func makeEntry(from appURL: URL) -> AppEntry? {
        guard let bundle = Bundle(url: appURL) else { return nil }

        let bundleId = bundle.bundleIdentifier ?? appURL.lastPathComponent
        let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? appURL.deletingPathExtension().lastPathComponent

        let keywords = tokenize(name)
        let searchName = Array(name.lowercased())
        let searchKeywords = keywords.dropFirst().map { Array($0) }

        return AppEntry(
            id: bundleId,
            name: name,
            path: appURL,
            keywords: keywords,
            searchName: searchName,
            searchKeywords: searchKeywords
        )
    }

    /// Tokenizes an app name into searchable keywords.
    ///
    /// Splits on spaces, hyphens, dots, and camelCase boundaries.
    /// For example, "Visual Studio Code" → ["visual", "studio", "code"]
    /// and "WebStorm" → ["web", "storm"]
    func tokenize(_ name: String) -> [String] {
        // Split on common delimiters
        let delimited = name.components(separatedBy: CharacterSet(charactersIn: " -._"))

        var tokens: [String] = []
        for part in delimited where !part.isEmpty {
            // Split camelCase
            let camelTokens = splitCamelCase(part)
            tokens.append(contentsOf: camelTokens.map { $0.lowercased() })
        }

        // Also add the full lowercased name as a keyword
        tokens.insert(name.lowercased(), at: 0)

        return tokens
    }

    private func splitCamelCase(_ string: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        for char in string {
            if char.isUppercase, !current.isEmpty {
                tokens.append(current)
                current = String(char)
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }
}
