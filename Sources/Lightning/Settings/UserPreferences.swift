import Foundation

/// User-configurable preferences backed by UserDefaults.
final class UserPreferences {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let maxResults = "maxResults"
        static let launchAtLogin = "launchAtLogin"
        static let additionalSearchPaths = "additionalSearchPaths"
    }

    /// Maximum number of search results to display (4-12).
    var maxResults: Int {
        get { max(4, min(12, defaults.integer(forKey: Keys.maxResults) == 0 ? 8 : defaults.integer(forKey: Keys.maxResults))) }
        set { defaults.set(newValue, forKey: Keys.maxResults) }
    }

    /// Whether to launch Lightning at login.
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    /// Additional directories to scan for applications.
    var additionalSearchPaths: [String] {
        get { defaults.stringArray(forKey: Keys.additionalSearchPaths) ?? [] }
        set { defaults.set(newValue, forKey: Keys.additionalSearchPaths) }
    }
}
