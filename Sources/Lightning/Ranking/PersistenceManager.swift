import Foundation

/// Manages JSON persistence of frecency and adaptive learning data.
///
/// Reads/writes to `~/Library/Application Support/Lightning/`.
/// Flushes periodically (every 30s) and on app termination.
final class PersistenceManager {
    /// Data container for JSON persistence.
    struct PersistedData: Codable {
        var frecencyRecords: [String: FrecencyTracker.Record]
        var adaptiveData: [String: [String: Int]]
    }

    private let frecencyTracker: FrecencyTracker
    private let adaptiveLearning: AdaptiveLearning
    private var flushTimer: Timer?

    private var dataDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Lightning")
    }

    private var dataFile: URL {
        dataDirectory.appendingPathComponent("data.json")
    }

    init(frecencyTracker: FrecencyTracker, adaptiveLearning: AdaptiveLearning) {
        self.frecencyTracker = frecencyTracker
        self.adaptiveLearning = adaptiveLearning
    }

    /// Loads persisted data from disk.
    func load() {
        guard FileManager.default.fileExists(atPath: dataFile.path) else { return }
        do {
            let data = try Data(contentsOf: dataFile)
            let decoded = try JSONDecoder().decode(PersistedData.self, from: data)
            frecencyTracker.load(decoded.frecencyRecords)
            adaptiveLearning.load(decoded.adaptiveData)
        } catch {
            print("Failed to load persisted data: \(error)")
        }
    }

    /// Saves current data to disk.
    func save() {
        let persisted = PersistedData(
            frecencyRecords: frecencyTracker.allRecords(),
            adaptiveData: adaptiveLearning.allData()
        )
        do {
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(persisted)
            try data.write(to: dataFile, options: .atomic)
        } catch {
            print("Failed to save persisted data: \(error)")
        }
    }

    /// Starts periodic flushing every 30 seconds.
    func startPeriodicFlush() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.save()
        }
    }

    /// Stops periodic flushing.
    func stopPeriodicFlush() {
        flushTimer?.invalidate()
        flushTimer = nil
    }
}
