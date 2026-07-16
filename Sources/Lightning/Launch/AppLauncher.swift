import AppKit

/// Launches applications via `NSWorkspace`.
enum AppLauncher {
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

    /// Opens the application in a *new window* in the current Space.
    ///
    /// The plain ``launch(_:)`` path activates an already-running instance,
    /// bringing its existing window forward — which makes focus-following window
    /// managers (e.g. AeroSpace) switch to whatever workspace that window lives
    /// in. This instead creates a fresh window so it is placed in the currently
    /// focused workspace.
    ///
    /// - If the app is not running, there is no existing window to avoid, so it
    ///   falls through to ``launch(_:)`` (the first window opens in the current
    ///   Space anyway).
    /// - If the app is running, it asks the running instance to make a new window
    ///   via AppleScript *without* activating the old windows. Apps that cannot be
    ///   scripted this way fall back to a new application instance.
    ///
    /// - Parameter entry: The app entry to open in a new window.
    static func launchNewWindow(_ entry: AppEntry) {
        let isRunning = !NSRunningApplication
            .runningApplications(withBundleIdentifier: entry.id)
            .isEmpty

        guard isRunning else {
            // Not running: a fresh launch opens its first window in the current Space.
            launch(entry)
            return
        }

        openNewWindowViaAppleScript(entry)
    }

    // MARK: - Private

    /// Asks a running app to create a new window via AppleScript.
    ///
    /// Runs `make new document` (Safari, document apps) and falls back to
    /// `make new window` (Chromium browsers and others) inside the script. The
    /// script deliberately omits `activate` so existing windows in other Spaces
    /// are not brought forward.
    ///
    /// Executed as an `osascript` subprocess on a background queue — never on the
    /// main thread. `NSAppleScript` is main-thread-affine and its
    /// `executeAndReturnError` blocks the calling thread until the target app
    /// replies and the first-run Automation (TCC) prompt is answered, which can be
    /// several seconds and would freeze the launcher. A subprocess keeps all of
    /// that off Lightning's threads. Apps that cannot be scripted this way (the
    /// subprocess exits non-zero) fall back to a new instance.
    ///
    /// - Parameter entry: The running app to open a new window for.
    private static func openNewWindowViaAppleScript(_ entry: AppEntry) {
        let source = """
        tell application id "\(entry.id)"
            try
                make new document
            on error
                make new window
            end try
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]
            // Never inherit the app's stdio.
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit() // blocks this background thread only
                if process.terminationStatus != 0 {
                    launchNewInstance(entry)
                }
            } catch {
                print("Failed to run osascript for \(entry.name): \(error.localizedDescription)")
                launchNewInstance(entry)
            }
        }
    }

    /// Launches a brand-new instance of the app (fallback for apps that cannot
    /// be scripted to make a new window).
    ///
    /// - Parameter entry: The app entry to launch as a new instance.
    private static func launchNewInstance(_ entry: AppEntry) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: entry.path, configuration: configuration) { _, error in
            if let error {
                print("Failed to open new instance of \(entry.name): \(error.localizedDescription)")
            }
        }
    }
}
