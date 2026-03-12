import Foundation

/// Orchestrates all filesystem and workspace monitors.
///
/// Debounces change callbacks (200ms) and manages a periodic full rescan
/// every 5 minutes as a safety net.
final class MonitorCoordinator {
    /// Callback fired when a rescan should be performed.
    var onRescanNeeded: (() -> Void)?

    private let directoryMonitor = DirectoryMonitor()
    private let fsEventsMonitor = FSEventsMonitor()
    private let workspaceMonitor = WorkspaceMonitor()

    private var debounceWorkItem: DispatchWorkItem?
    private var rescanTimer: Timer?
    private let debounceInterval: TimeInterval = 0.2

    /// Starts all monitors.
    func start() {
        // Watch flat application directories with kqueue
        let flatDirs = AppScanner.defaultSearchPaths
        directoryMonitor.watch(directories: flatDirs)
        directoryMonitor.onChange = { [weak self] _ in
            self?.debounceRescan()
        }

        // Watch deep hierarchies (cloud storage) with FSEvents
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudStorage = home.appendingPathComponent("Library/CloudStorage").path
        fsEventsMonitor.watch(paths: [cloudStorage])
        fsEventsMonitor.onChange = { [weak self] path in
            if path.hasSuffix(".app") || path.contains(".app/") {
                self?.debounceRescan()
            }
        }

        // Watch workspace events
        workspaceMonitor.start()
        workspaceMonitor.onAppEvent = { [weak self] in
            self?.debounceRescan()
        }

        // Periodic full rescan every 5 minutes
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.onRescanNeeded?()
        }
    }

    /// Stops all monitors.
    func stop() {
        directoryMonitor.stopAll()
        fsEventsMonitor.stop()
        workspaceMonitor.stop()
        rescanTimer?.invalidate()
        rescanTimer = nil
    }

    // MARK: - Private

    private func debounceRescan() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.onRescanNeeded?()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
