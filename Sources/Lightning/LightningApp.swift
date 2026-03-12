import AppKit
import SwiftUI

/// The main application delegate for Lightning.
///
/// Manages the app lifecycle, sets the activation policy to `.accessory`
/// (no Dock icon), and wires up the global hotkey, panel controller,
/// app index, monitoring, ranking, persistence, and status bar item.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PanelController!
    private var globalHotKey: GlobalHotKeyManager!
    private let appIndex = AppIndex()
    private let iconCache = IconCache()
    private let appScanner = AppScanner()
    private let frecencyTracker = FrecencyTracker()
    private let adaptiveLearning = AdaptiveLearning()
    private var persistenceManager: PersistenceManager!
    private var monitorCoordinator: MonitorCoordinator!
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Initialize persistence and load saved data
        persistenceManager = PersistenceManager(
            frecencyTracker: frecencyTracker,
            adaptiveLearning: adaptiveLearning
        )
        persistenceManager.load()
        persistenceManager.startPeriodicFlush()

        // Set up panel controller with all dependencies
        panelController = PanelController()
        panelController.searchViewModel.configure(
            appIndex: appIndex,
            iconCache: iconCache,
            frecencyTracker: frecencyTracker,
            adaptiveLearning: adaptiveLearning
        )

        globalHotKey = GlobalHotKeyManager(panelController: panelController)

        // Set up status bar item
        updateStatusItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarIconPreferenceChanged),
            name: UserPreferences.menuBarIconDidChangeNotification,
            object: nil
        )

        // Start filesystem monitoring
        monitorCoordinator = MonitorCoordinator()
        monitorCoordinator.onRescanNeeded = { [weak self] in
            self?.performRescan()
        }
        monitorCoordinator.start()

        // Perform initial scan
        performInitialScan()

        // Save on termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTermination),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        panelController.show()
        return true
    }

    @objc private func handleTermination(_: Notification) {
        monitorCoordinator.stop()
        persistenceManager.stopPeriodicFlush()
        persistenceManager.save()
    }

    // MARK: - Status Bar

    @objc private func menuBarIconPreferenceChanged() {
        updateStatusItem()
    }

    private func updateStatusItem() {
        if UserPreferences.shared.showMenuBarIcon {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
                if let button = statusItem?.button {
                    button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Lightning")
                }

                let menu = NSMenu()
                menu.addItem(NSMenuItem(title: "Open Lightning", action: #selector(openLightning), keyEquivalent: ""))
                menu.addItem(.separator())
                menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
                menu.addItem(.separator())
                menu.addItem(NSMenuItem(title: "Quit Lightning", action: #selector(quitApp), keyEquivalent: "q"))

                statusItem?.menu = menu
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    @objc private func openLightning() {
        panelController.show()
    }

    @objc private func openSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Lightning Launcher Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Scanning

    private func performInitialScan() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let additionalPaths = UserPreferences.shared.additionalSearchPaths.map { URL(fileURLWithPath: $0) }
            let entries = appScanner.scan(additionalPaths: additionalPaths)
            appIndex.update(with: entries)

            Task {
                await self.iconCache.preload(entries: entries)
            }
        }
    }

    private func performRescan() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let additionalPaths = UserPreferences.shared.additionalSearchPaths.map { URL(fileURLWithPath: $0) }
            let entries = appScanner.scan(additionalPaths: additionalPaths)
            appIndex.update(with: entries)

            Task {
                await self.iconCache.preload(entries: entries)
            }
        }
    }
}
