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

/// A custom NSTextField wrapper that intercepts arrow keys, Return, and Escape.
///
/// Key events are intercepted via the `NSTextFieldDelegate` method
/// `control(_:textView:doCommandBy:)`, which catches commands from the
/// field editor (the NSTextView that handles editing inside NSTextField).
/// This is necessary because the field editor becomes first responder
/// during editing, so `keyDown` on the NSTextField itself never fires.
struct KeyboardTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void
    var onReturn: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: 22, weight: .light)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Compare against the field editor's live text when editing is active
        // to avoid setting stringValue mid-edit (which selects all text).
        let currentText = (nsView.currentEditor() as? NSTextView)?.string ?? nsView.stringValue
        if currentText != text {
            nsView.stringValue = text
        }
        // Keep callbacks up to date
        context.coordinator.parent = self
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

        /// Intercepts commands from the field editor before they are executed.
        ///
        /// This is the correct place to handle Escape, arrow keys, and Return
        /// for an NSTextField, since the field editor (NSTextView) is the actual
        /// first responder during editing.
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.cancelOperation(_:)):
                // Escape
                parent.onEscape()
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.onArrowUp()
                return true
            case #selector(NSResponder.moveDown(_:)):
                parent.onArrowDown()
                return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.onReturn()
                return true
            default:
                return false
            }
        }
    }
}
