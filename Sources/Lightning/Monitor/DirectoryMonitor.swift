import Foundation

/// Monitors flat directories using kqueue/DispatchSource for changes.
///
/// Watches directories like `/Applications` for file creation, deletion,
/// or rename events. Uses `O_EVTONLY` to avoid preventing unmounts.
final class DirectoryMonitor {
    /// Callback fired when a change is detected in a monitored directory.
    var onChange: ((URL) -> Void)?

    private var sources: [URL: DispatchSourceFileSystemObject] = [:]
    private let queue = DispatchQueue(label: "com.lightning.directoryMonitor", qos: .utility)

    /// Starts monitoring the specified directories.
    func watch(directories: [URL]) {
        for dir in directories {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }
            startMonitoring(directory: dir)
        }
    }

    /// Stops all monitoring.
    func stopAll() {
        for (_, source) in sources {
            source.cancel()
        }
        sources.removeAll()
    }

    // MARK: - Private

    private func startMonitoring(directory: URL) {
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.onChange?(directory)
        }

        source.setCancelHandler {
            close(fd)
        }

        sources[directory] = source
        source.resume()
    }
}
