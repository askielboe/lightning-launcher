import HotKey
import Carbon

/// Manages the global hotkey (Option+Space) that toggles the search panel.
///
/// Uses the `soffes/HotKey` library which registers via the Carbon Events API,
/// avoiding the need for Accessibility permissions.
final class GlobalHotKeyManager {
    private let hotKey: HotKey
    private weak var panelController: PanelController?

    init(panelController: PanelController) {
        self.panelController = panelController
        self.hotKey = HotKey(key: .space, modifiers: [.option])

        self.hotKey.keyDownHandler = { [weak panelController] in
            panelController?.toggle()
        }
    }
}
