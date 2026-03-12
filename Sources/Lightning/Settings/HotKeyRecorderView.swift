import HotKey
import SwiftUI

/// A view that records a new global hotkey combination.
///
/// When active, captures the next key+modifier combination the user presses
/// and saves it to UserPreferences.
struct HotKeyRecorderView: View {
    @State private var isRecording = false
    @State private var displayString: String

    init() {
        _displayString = State(initialValue: Self.currentHotKeyString())
    }

    var body: some View {
        HStack {
            Text("Hotkey")
            Spacer()
            Button(action: {
                isRecording.toggle()
            }, label: {
                Text(isRecording ? "Press a key combo..." : displayString)
                    .frame(minWidth: 100)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            })
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                HotKeyRecorderNSView(
                    isRecording: $isRecording,
                    displayString: $displayString
                )
                .frame(width: 0, height: 0)
                .opacity(0)
            )
        }
    }

    /// Returns a human-readable string for the current hotkey configuration.
    static func currentHotKeyString() -> String {
        let prefs = UserPreferences.shared
        let modifiers = NSEvent.ModifierFlags(rawValue: prefs.hotKeyModifiers)
        let keyCode = prefs.hotKeyCode
        let key = Key(carbonKeyCode: keyCode)

        var parts = ""
        if modifiers.contains(.control) { parts += "\u{2303}" }
        if modifiers.contains(.option) { parts += "\u{2325}" }
        if modifiers.contains(.shift) { parts += "\u{21E7}" }
        if modifiers.contains(.command) { parts += "\u{2318}" }

        if let key {
            parts += key.description
        } else if let str = KeyCombo.carbonKeyCodeToString(keyCode) {
            parts += str.uppercased()
        } else {
            parts += "Key(\(keyCode))"
        }

        return parts
    }
}

/// An invisible NSView that captures keyboard events when recording is active.
struct HotKeyRecorderNSView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var displayString: String

    func makeNSView(context _: Context) -> HotKeyRecorderEventView {
        let view = HotKeyRecorderEventView()
        view.onKeyCombo = { keyCode, modifiers in
            saveHotKey(keyCode: keyCode, modifiers: modifiers)
        }
        return view
    }

    func updateNSView(_ nsView: HotKeyRecorderEventView, context _: Context) {
        nsView.isRecordingEnabled = isRecording
        nsView.onKeyCombo = { keyCode, modifiers in
            saveHotKey(keyCode: keyCode, modifiers: modifiers)
        }
    }

    private func saveHotKey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        // Require at least one modifier key
        let validModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        let pressedModifiers = modifiers.intersection(validModifiers)
        guard !pressedModifiers.isEmpty else { return }

        let prefs = UserPreferences.shared
        prefs.hotKeyCode = UInt32(keyCode)
        prefs.hotKeyModifiers = pressedModifiers.rawValue

        displayString = HotKeyRecorderView.currentHotKeyString()
        isRecording = false
    }
}

/// NSView subclass that monitors keyboard events globally when recording.
final class HotKeyRecorderEventView: NSView {
    var isRecordingEnabled = false
    var onKeyCombo: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Use a local event monitor to capture key events
        if monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, isRecordingEnabled else { return event }
                onKeyCombo?(event.keyCode, event.modifierFlags)
                return nil // Consume the event
            }
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
