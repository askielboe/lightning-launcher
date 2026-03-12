import Foundation
import AppKit

/// User-configurable preferences backed by UserDefaults.
final class UserPreferences {
    static let shared = UserPreferences()

    /// Posted when the hotkey configuration changes.
    static let hotKeyDidChangeNotification = Notification.Name("LightningHotKeyDidChange")

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let maxResults = "maxResults"
        static let launchAtLogin = "launchAtLogin"
        static let additionalSearchPaths = "additionalSearchPaths"
        static let hotKeyCode = "hotKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let showSearchIcon = "showSearchIcon"
        static let removedDefaultPaths = "removedDefaultPaths"
        static let showMenuBarIcon = "showMenuBarIcon"
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

    /// Default search paths that have been removed by the user.
    var removedDefaultPaths: [String] {
        get { defaults.stringArray(forKey: Keys.removedDefaultPaths) ?? [] }
        set { defaults.set(newValue, forKey: Keys.removedDefaultPaths) }
    }

    /// Whether to show the menu bar icon.
    var showMenuBarIcon: Bool {
        get { defaults.object(forKey: Keys.showMenuBarIcon) == nil ? true : defaults.bool(forKey: Keys.showMenuBarIcon) }
        set { defaults.set(newValue, forKey: Keys.showMenuBarIcon) }
    }

    /// Posted when the menu bar icon visibility changes.
    static let menuBarIconDidChangeNotification = Notification.Name("LightningMenuBarIconDidChange")

    /// Whether to show the lightning bolt icon in the search field.
    var showSearchIcon: Bool {
        get { defaults.object(forKey: Keys.showSearchIcon) == nil ? true : defaults.bool(forKey: Keys.showSearchIcon) }
        set { defaults.set(newValue, forKey: Keys.showSearchIcon) }
    }

    /// The key code for the global hotkey. Default is 49 (Space).
    var hotKeyCode: UInt32 {
        get {
            let stored = defaults.integer(forKey: Keys.hotKeyCode)
            return stored == 0 ? 49 : UInt32(stored) // 49 = Space
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.hotKeyCode)
            NotificationCenter.default.post(name: Self.hotKeyDidChangeNotification, object: nil)
        }
    }

    /// The modifier flags for the global hotkey as a raw UInt value.
    /// Default is Option (NSEvent.ModifierFlags.option).
    var hotKeyModifiers: UInt {
        get {
            let stored = defaults.integer(forKey: Keys.hotKeyModifiers)
            return stored == 0 ? NSEvent.ModifierFlags.option.rawValue : UInt(stored)
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.hotKeyModifiers)
            NotificationCenter.default.post(name: Self.hotKeyDidChangeNotification, object: nil)
        }
    }
}
