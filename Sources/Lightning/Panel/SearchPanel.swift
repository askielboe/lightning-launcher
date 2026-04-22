import AppKit

/// A floating, non-activating, borderless panel used as the search overlay.
///
/// This panel stays above other windows, becomes key (for keyboard input)
/// but never becomes main, and dismisses on Escape.
final class SearchPanel: NSPanel {
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
        // Standard editing commands — menu key equivalents don't fire for non-activating panels,
        // so forward them to the field editor directly (not via NSApp.sendAction, which can
        // cause transient key-status changes that dismiss the panel).
        if event.modifierFlags.contains(.command), let chars = event.charactersIgnoringModifiers,
           let fieldEditor = firstResponder as? NSTextView
        {
            switch chars {
            case "v": fieldEditor.paste(nil); return true
            case "c": fieldEditor.copy(nil); return true
            case "x": fieldEditor.cut(nil); return true
            case "a": fieldEditor.selectAll(nil); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
