import HotKey
import AppKit

/// Manages the global hotkey that toggles the search panel.
///
/// Uses the `soffes/HotKey` library which registers via the Carbon Events API,
/// avoiding the need for Accessibility permissions. Supports runtime rebinding
/// when the user changes the hotkey in Settings.
final class GlobalHotKeyManager {
    private var hotKey: HotKey?
    private weak var panelController: PanelController?

    init(panelController: PanelController) {
        self.panelController = panelController
        bindFromPreferences()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotKeyPreferencesChanged),
            name: UserPreferences.hotKeyDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Rebinds the hotkey from current user preferences.
    func bindFromPreferences() {
        let prefs = UserPreferences.shared
        let keyCode = prefs.hotKeyCode
        let modifierFlags = NSEvent.ModifierFlags(rawValue: prefs.hotKeyModifiers)

        guard let key = Key(carbonKeyCode: keyCode) else { return }

        // Tear down the old hotkey
        hotKey = nil

        let newHotKey = HotKey(key: key, modifiers: modifierFlags)
        newHotKey.keyDownHandler = { [weak self] in
            self?.panelController?.toggle()
        }
        hotKey = newHotKey
    }

    @objc private func hotKeyPreferencesChanged() {
        bindFromPreferences()
    }
}
