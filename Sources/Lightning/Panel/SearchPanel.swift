import AppKit

/// A floating, non-activating, borderless panel used as the search overlay.
///
/// This panel stays above other windows, becomes key (for keyboard input)
/// but never becomes main, and dismisses on Escape.
final class SearchPanel: NSPanel {
    /// Called when Cmd+Return is pressed — request opening the selected result
    /// in a new window in the current Space.
    var onCommandReturn: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Cmd+, opens settings (menu key equivalents don't work for non-activating panels)
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "," {
            NSApp.sendAction(#selector(AppDelegate.openSettings), to: NSApp.delegate, from: nil)
            return true
        }
        // Cmd+Q quits the app
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" {
            NSApp.terminate(nil)
            return true
        }
        // Cmd+Return opens the selected result in a new window in the current Space
        // (rather than activating an existing window, which follows focus to another
        // Space/AeroSpace workspace). keyCode 36 = Return, 76 = keypad Enter.
        // Consuming the event here keeps it from also firing as a newline.
        if event.modifierFlags.contains(.command), event.keyCode == 36 || event.keyCode == 76 {
            onCommandReturn?()
            return true
        }
        // Standard editing commands — menu key equivalents don't fire for non-activating panels.
        // Forward the event to the field editor via keyDown so it flows through the normal
        // interpretKeyEvents → key bindings → doCommandBySelector → delegate chain.
        if event.modifierFlags.contains(.command), let chars = event.charactersIgnoringModifiers,
           ["v", "c", "x", "a"].contains(chars),
           let fieldEditor = firstResponder as? NSTextView
        {
            fieldEditor.keyDown(with: event)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
