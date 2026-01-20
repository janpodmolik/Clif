import Foundation

/// JSONL append-only store for snapshot events.
/// Stores events in App Group container for cross-process access (main app + DeviceActivityMonitor).
final class SnapshotStore {

    // MARK: - Singleton

    static let shared = SnapshotStore()

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.clif.snapshotstore", qos: .utility)

    /// File URL for the JSONL log in App Group container.
    private var logFileURL: URL? {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            #if DEBUG
            print("SnapshotStore: Failed to get App Group container")
            #endif
            return nil
        }
        return containerURL.appendingPathComponent("snapshots.jsonl")
    }

    // MARK: - Init

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [] // Compact, no pretty print

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public API

    /// Appends a single event to the log file.
    /// Thread-safe, can be called from any queue.
    func append(_ event: SnapshotEvent) {
        queue.async { [weak self] in
            self?.appendSync(event)
        }
    }

    /// Appends a single event synchronously.
    /// Use this when you need to ensure the event is written before continuing.
    func appendSync(_ event: SnapshotEvent) {
        guard let url = logFileURL else { return }

        do {
            let data = try encoder.encode(event)
            guard var line = String(data: data, encoding: .utf8) else { return }
            line.append("\n")

            if fileManager.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                if let lineData = line.data(using: .utf8) {
                    try handle.write(contentsOf: lineData)
                }
                try handle.close()
            } else {
                try line.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            #if DEBUG
            print("SnapshotStore: Failed to append event: \(error)")
            #endif
        }
    }

    /// Loads all events from the log file.
    func loadAll() -> [SnapshotEvent] {
        guard let url = logFileURL,
              fileManager.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return parseJSONL(content)
        } catch {
            #if DEBUG
            print("SnapshotStore: Failed to load events: \(error)")
            #endif
            return []
        }
    }

    /// Loads events for a specific date.
    func load(for date: String) -> [SnapshotEvent] {
        loadAll().filter { $0.date == date }
    }

    /// Loads events for a specific pet.
    func load(petId: UUID) -> [SnapshotEvent] {
        loadAll().filter { $0.petId == petId }
    }

    /// Loads events grouped by date.
    func loadGroupedByDate() -> [String: [SnapshotEvent]] {
        Dictionary(grouping: loadAll(), by: { $0.date })
    }

    /// Loads events for a date range (inclusive).
    func load(from startDate: String, to endDate: String) -> [SnapshotEvent] {
        loadAll().filter { $0.date >= startDate && $0.date <= endDate }
    }

    /// Returns the count of events in the log.
    func count() -> Int {
        loadAll().count
    }

    /// Deletes events older than the specified date.
    /// Returns the number of events retained.
    @discardableResult
    func pruneEvents(olderThan cutoffDate: String) -> Int {
        let events = loadAll()
        let retained = events.filter { $0.date >= cutoffDate }

        guard retained.count < events.count else { return events.count }

        rewriteLog(with: retained)
        return retained.count
    }

    /// Clears all events from the log.
    func clearAll() {
        guard let url = logFileURL else { return }
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Sync Support

    /// Loads events that haven't been synced yet (after the given offset).
    /// Returns events and the new offset (total count after these events).
    func loadUnsynced(afterOffset offset: Int) -> (events: [SnapshotEvent], newOffset: Int) {
        let all = loadAll()
        guard offset < all.count else {
            return ([], all.count)
        }
        let unsynced = Array(all[offset...])
        return (unsynced, all.count)
    }

    // MARK: - Private Helpers

    private func parseJSONL(_ content: String) -> [SnapshotEvent] {
        content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> SnapshotEvent? in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(SnapshotEvent.self, from: data)
            }
    }

    private func rewriteLog(with events: [SnapshotEvent]) {
        guard let url = logFileURL else { return }

        do {
            let lines = events.compactMap { event -> String? in
                guard let data = try? encoder.encode(event),
                      let line = String(data: data, encoding: .utf8) else { return nil }
                return line
            }
            let content = lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            #if DEBUG
            print("SnapshotStore: Failed to rewrite log: \(error)")
            #endif
        }
    }
}
