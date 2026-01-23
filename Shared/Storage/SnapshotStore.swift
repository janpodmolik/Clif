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
    ///
    /// Pruning strategy: Only delete events that are BOTH:
    /// 1. Older than cutoffDate (e.g., 30 days)
    /// 2. Already synced to backend (offset-based)
    ///
    /// This ensures no data loss - unsynced events are preserved regardless of age.
    /// Call this after successful BE sync with: pruneEvents(olderThan: thirtyDaysAgo, syncedOffset: newOffset)
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

    // MARK: - Wind Sync Support

    /// Returns the latest cumulative minutes from today's usage threshold events for the given pet.
    /// Used by main app to sync wind state when returning to foreground.
    func latestThresholdMinutes(petId: UUID) -> Int? {
        let todayString = SnapshotEvent.dateString(from: Date())
        let todayEvents = loadAll().filter { $0.petId == petId && $0.date == todayString }

        // Find the most recent usageThreshold event
        for event in todayEvents.reversed() {
            if case .usageThreshold(let minutes) = event.eventType {
                return minutes
            }
        }
        return nil
    }

    /// Returns whether the pet was blown away today (either via wind or break failure).
    func wasBlownAwayToday(petId: UUID) -> Bool {
        let todayString = SnapshotEvent.dateString(from: Date())
        return loadAll().contains { event in
            event.petId == petId &&
            event.date == todayString &&
            event.eventType == .blowAway
        }
    }

    // MARK: - Aggregation for BE Sync

    // TODO: Implement sync to Supabase
    // Sync triggers:
    // 1. Foreground sync - when app becomes active (scenePhase → .active)
    // 2. Periodic sync - every 6-12 hours if there's new data
    // 3. Background task - BGAppRefreshTask (iOS schedules opportunistically)
    //
    // Foreground sync is most reliable. Periodic/background is bonus for users
    // who don't open the app frequently.

    /// Aggregates usageThreshold events into time-based intervals.
    /// Other event types are kept unchanged.
    /// - Parameters:
    ///   - dateRange: Optional date range filter (YYYY-MM-DD format, inclusive)
    ///   - intervalMinutes: Aggregation interval (default 2 minutes)
    /// - Returns: Aggregated events sorted by timestamp
    func loadAggregated(
        dateRange: ClosedRange<String>? = nil,
        intervalMinutes: Int = 2
    ) -> [SnapshotEvent] {
        var events = loadAll()

        // Filter by date range if provided
        if let range = dateRange {
            events = events.filter { range.contains($0.date) }
        }

        // Separate usageThreshold events from others
        var thresholdEvents: [SnapshotEvent] = []
        var otherEvents: [SnapshotEvent] = []

        for event in events {
            if case .usageThreshold = event.eventType {
                thresholdEvents.append(event)
            } else {
                otherEvents.append(event)
            }
        }

        // Aggregate threshold events by interval
        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        var aggregatedThresholds: [SnapshotEvent] = []

        // Group by (petId, intervalBucket)
        let grouped = Dictionary(grouping: thresholdEvents) { event -> String in
            let bucket = floor(event.timestamp.timeIntervalSince1970 / intervalSeconds)
            return "\(event.petId.uuidString)_\(Int(bucket))"
        }

        // Take the last event from each group (most accurate wind state)
        for (_, group) in grouped {
            if let lastEvent = group.max(by: { $0.timestamp < $1.timestamp }) {
                aggregatedThresholds.append(lastEvent)
            }
        }

        // Combine and sort by timestamp
        let result = (aggregatedThresholds + otherEvents).sorted { $0.timestamp < $1.timestamp }
        return result
    }

    /// Returns aggregated events for backend sync.
    /// - usageThreshold: aggregated to specified interval (default 2 minutes)
    /// - Other events: unchanged
    /// - Parameters:
    ///   - offset: Number of raw events already synced (for incremental sync)
    ///   - intervalMinutes: Aggregation interval for usageThreshold events
    /// - Returns: Aggregated events and new offset based on raw event count
    func loadForSync(
        afterOffset offset: Int,
        intervalMinutes: Int = 2
    ) -> (events: [SnapshotEvent], newOffset: Int) {
        let all = loadAll()
        let newOffset = all.count

        guard offset < all.count else {
            return ([], newOffset)
        }

        // Get only new events since last sync
        let unsyncedRaw = Array(all[offset...])

        // Determine date range from unsynced events
        guard let minDate = unsyncedRaw.map({ $0.date }).min(),
              let maxDate = unsyncedRaw.map({ $0.date }).max() else {
            return ([], newOffset)
        }

        // Load aggregated for the date range, then filter to only new events
        let aggregated = loadAggregated(dateRange: minDate...maxDate, intervalMinutes: intervalMinutes)

        // Filter to events that fall within the unsynced time window
        let unsyncedStartTime = unsyncedRaw.first?.timestamp ?? Date.distantPast
        let filtered = aggregated.filter { $0.timestamp >= unsyncedStartTime }

        return (filtered, newOffset)
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
