import CoreServices
import Foundation

/// Monitors deep directory hierarchies using CoreServices FSEvents.
///
/// Used for directories like `~/Library/CloudStorage/` where apps might
/// be nested several levels deep. Provides file-level event granularity.
final class FSEventsMonitor {
    /// Callback fired when changes are detected in monitored paths.
    var onChange: ((String) -> Void)?

    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.lightning.fseventsMonitor", qos: .utility)

    /// Starts monitoring the specified paths.
    func watch(paths: [String]) {
        let existingPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }
        guard !existingPaths.isEmpty else { return }

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<FSEventsMonitor>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(eventPaths, to: NSArray.self)
            for i in 0 ..< numEvents {
                if let path = paths[i] as? String {
                    monitor.onChange?(path)
                }
            }
        }

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            existingPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // 500ms latency
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }

    /// Stops monitoring.
    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        stop()
    }
}
