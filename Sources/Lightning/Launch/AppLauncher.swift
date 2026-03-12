import AppKit

/// Launches applications via `NSWorkspace`.
struct AppLauncher {
    /// Launches the application at the given URL.
    ///
    /// - Parameter entry: The app entry to launch.
    static func launch(_ entry: AppEntry) {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: entry.path, configuration: configuration) { _, error in
            if let error {
                print("Failed to launch \(entry.name): \(error.localizedDescription)")
            }
        }
    }
}
