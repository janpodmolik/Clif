import Foundation

/// A single event in the snapshot log.
/// Events are append-only and represent state changes for analytics/premium graphs.
/// The source of truth for game mechanics remains in DailyPet/DynamicPet aggregates.
struct SnapshotEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let petId: UUID
    let mode: PetMode
    /// Date in YYYY-MM-DD format. Redundant (derivable from timestamp) but simplifies
    /// BE queries and indexing for group-by-day operations.
    let date: String
    let timestamp: Date
    let windPoints: Double
    let schemaVersion: Int
    let eventType: SnapshotEventType

    init(
        id: UUID = UUID(),
        petId: UUID,
        mode: PetMode,
        date: String? = nil,
        timestamp: Date = Date(),
        windPoints: Double,
        eventType: SnapshotEventType
    ) {
        self.id = id
        self.petId = petId
        self.mode = mode
        self.date = date ?? Self.dateString(from: timestamp)
        self.timestamp = timestamp
        self.windPoints = windPoints
        self.schemaVersion = SnapshotSchema.currentVersion
        self.eventType = eventType
    }

    // MARK: - Date Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

// MARK: - Schema Versioning

enum SnapshotSchema {
    static let currentVersion = 1
}

// MARK: - Pet Mode

enum PetMode: String, Codable, Equatable {
    case daily
    case dynamic
}
