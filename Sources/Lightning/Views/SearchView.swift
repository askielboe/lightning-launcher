import SwiftUI

/// The root SwiftUI view hosted inside the search panel.
///
/// Contains the search text field, results list, and handles keyboard
/// navigation (arrow keys, Return, Escape).
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if !viewModel.results.isEmpty {
                Divider()
                    .padding(.horizontal, 8)

                ResultsList(
                    results: viewModel.results,
                    selectedIndex: viewModel.selectedIndex,
                    onSelect: { entry in
                        viewModel.launch(entry)
                    }
                )
                .padding(.vertical, 4)
            }
        }
        .frame(width: PanelController.panelWidth)
        .background(VisualEffectBackground())
    }

    private var searchField: some View {
        KeyboardTextField(
            text: $viewModel.query,
            placeholder: "Search apps...",
            onArrowUp: { viewModel.moveUp() },
            onArrowDown: { viewModel.moveDown() },
            onReturn: { viewModel.launchSelected() },
            onEscape: { viewModel.dismiss() }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: PanelController.searchFieldHeight)
    }
}

/// A custom NSTextField wrapper that intercepts arrow keys and Return.
///
/// SwiftUI's `TextField` doesn't expose keyboard events, so we use
/// an `NSViewRepresentable` to capture navigation keys.
struct KeyboardTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void
    var onReturn: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = CallbackTextField()
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: 22, weight: .light)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.onArrowUp = onArrowUp
        field.onArrowDown = onArrowDown
        field.onReturn = onReturn
        field.onEscape = onEscape
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if let field = nsView as? CallbackTextField {
            field.onArrowUp = onArrowUp
            field.onArrowDown = onArrowDown
            field.onReturn = onReturn
            field.onEscape = onEscape
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: KeyboardTextField

        init(_ parent: KeyboardTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }
    }
}

/// NSTextField subclass that intercepts arrow and Return key events.
final class CallbackTextField: NSTextField {
    var onArrowUp: (() -> Void)?
    var onArrowDown: (() -> Void)?
    var onReturn: (() -> Void)?
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            onEscape?()
        case 126: // Arrow Up
            onArrowUp?()
        case 125: // Arrow Down
            onArrowDown?()
        case 36: // Return
            onReturn?()
        default:
            super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        // Ensure the cursor is at the end
        if let editor = currentEditor() {
            editor.selectedRange = NSRange(location: stringValue.count, length: 0)
        }
        return result
    }
}
