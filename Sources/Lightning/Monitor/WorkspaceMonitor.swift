import AppKit

/// Monitors NSWorkspace notifications for app launch/termination events.
///
/// Provides immediate awareness of running applications without
/// filesystem scanning.
final class WorkspaceMonitor {
    /// Callback fired when an app is launched or terminated.
    var onAppEvent: (() -> Void)?

    /// Starts observing workspace notifications.
    func start() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(
            self,
            selector: #selector(handleAppEvent),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppEvent),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    /// Stops observing.
    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func handleAppEvent(_: Notification) {
        onAppEvent?()
    }

    deinit {
        stop()
    }
}
