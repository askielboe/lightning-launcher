import AppKit
import SwiftUI

/// Owns the floating search panel and manages its visibility and positioning.
///
/// The panel is pre-warmed (created once at init) and shown/hidden as needed,
/// avoiding window creation overhead on the hotkey path.
final class PanelController {
    private let panel: SearchPanel
    private var eventMonitor: Any?
    private var globalEventMonitor: Any?
    let searchViewModel = SearchViewModel()

    /// The panel width.
    static let panelWidth: CGFloat = 680

    /// Height of just the search field.
    static let searchFieldHeight: CGFloat = 52

    init() {
        let frame = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.searchFieldHeight)
        panel = SearchPanel(contentRect: frame)

        let hostingView = NSHostingView(rootView: SearchView(viewModel: searchViewModel))
        hostingView.frame = frame
        panel.contentView = hostingView

        searchViewModel.onHeightChange = { [weak self] height in
            self?.updatePanelHeight(height)
        }
        searchViewModel.onDismiss = { [weak self] in
            self?.hide()
        }

        setupClickOutsideMonitor()
    }

    /// Toggles panel visibility.
    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    /// Shows the panel centered near the top of the active screen with fade-in.
    func show() {
        positionPanel()
        // Reset height to search field only before showing
        let frame = NSRect(
            x: panel.frame.origin.x,
            y: panel.frame.origin.y,
            width: Self.panelWidth,
            height: Self.searchFieldHeight
        )
        panel.setFrame(frame, display: false)
        searchViewModel.activate()

        // Fade in
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            panel.animator().alphaValue = 1
        }

        // Focus the text field
        panel.makeFirstResponder(findTextField(in: panel.contentView))
    }

    /// Hides the panel and clears the search state.
    func hide() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.08
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
            self?.panel.alphaValue = 1
        })
        searchViewModel.deactivate()
    }

    /// Updates the panel height to accommodate results.
    func updatePanelHeight(_ height: CGFloat) {
        var frame = panel.frame
        let oldHeight = frame.height
        frame.size.height = height
        // Grow downward: keep the top edge fixed
        frame.origin.y -= (height - oldHeight)
        panel.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Private

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - Self.panelWidth / 2
        // Position near the top third of the screen
        let y = screenFrame.maxY - 220
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func setupClickOutsideMonitor() {
        // Clicks on other windows within the app
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            if event.window != self.panel {
                self.hide()
            }
            return event
        }
        // Clicks on windows of other apps
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.panel.isVisible else { return }
            self.hide()
        }

        // Hide when the panel loses key status (e.g. Cmd+Tab, Mission Control)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.panel.isVisible else { return }
            self.hide()
        }
    }

    /// Recursively finds the first NSTextField in the view hierarchy.
    private func findTextField(in view: NSView?) -> NSTextField? {
        guard let view else { return nil }
        if let tf = view as? NSTextField, tf.isEditable { return tf }
        for subview in view.subviews {
            if let tf = findTextField(in: subview) { return tf }
        }
        return nil
    }
}
