import Foundation

// MARK: - Cached Detail Type

enum ArchivedPetDetail: Identifiable {
    case daily(ArchivedDailyPet)
    case dynamic(ArchivedDynamicPet)

    var id: UUID {
        switch self {
        case .daily(let pet): pet.id
        case .dynamic(let pet): pet.id
        }
    }
}

// MARK: - Manager

@Observable
final class ArchivedPetManager {
    // MARK: - Public State

    /// All archived pet summaries, sorted by archivedAt (newest first).
    private(set) var summaries: [ArchivedPetSummary] = []

    /// Loading state for summaries.
    private(set) var isLoadingSummaries = false

    // MARK: - Private Cache (LRU, newest at end)

    private var detailCache: [ArchivedPetDetail] = []
    private let maxCacheSize = 5

    // MARK: - Storage URLs
    //
    // Temporary FileManager-based storage. Will be replaced by Supabase.
    //
    // Current structure (FileManager):
    //   archived_summaries.json     ← all summaries (lightweight, for listing)
    //   archived/{id}.json          ← individual details (full data)
    //   Note: Summary data is duplicated in both files.
    //
    // Future structure (Supabase):
    //   Single table `archived_pets` with all columns.
    //   Listing: SELECT id, name, phase, archived_at, is_blown...
    //   Detail:  SELECT *
    //   No data duplication - just different Swift structs for different views.

    private static let documentsURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private static let summariesURL: URL = {
        documentsURL.appendingPathComponent("archived_summaries.json")
    }()

    private static let archivedDirectoryURL: URL = {
        documentsURL.appendingPathComponent("archived")
    }()

    private static func detailURL(for id: UUID) -> URL {
        archivedDirectoryURL.appendingPathComponent("\(id.uuidString).json")
    }

    // MARK: - Init

    init() {}

    // MARK: - Public API: Load Summaries

    /// Load summaries if not already loaded. Call when OverviewScreen appears.
    func loadSummariesIfNeeded() {
        guard summaries.isEmpty, !isLoadingSummaries else { return }
        isLoadingSummaries = true
        loadSummaries()
        isLoadingSummaries = false
    }

    // MARK: - Public API: Load Detail

    /// Load full detail for an archived pet.
    func loadDetail(for summary: ArchivedPetSummary) async -> ArchivedPetDetail? {
        if let cached = detailCache.first(where: { $0.id == summary.id }) {
            return cached
        }

        let detail: ArchivedPetDetail? = switch summary.petType {
        case .daily: loadFromDisk(id: summary.id, as: ArchivedDailyPet.self).map { .daily($0) }
        case .dynamic: loadFromDisk(id: summary.id, as: ArchivedDynamicPet.self).map { .dynamic($0) }
        }

        if let detail {
            await MainActor.run { cacheDetail(detail) }
        }

        return detail
    }

    // MARK: - Public API: Archive

    /// Archive an active pet.
    func archive(_ pet: ActivePet) {
        switch pet {
        case .daily(let daily): archive(daily)
        case .dynamic(let dynamic): archive(dynamic)
        }
    }

    /// Archive a DailyPet.
    func archive(_ pet: DailyPet) {
        let archived = ArchivedDailyPet(archiving: pet)
        let summary = ArchivedPetSummary(from: archived)

        saveDetail(archived, for: pet.id)
        summaries.insert(summary, at: 0)
        saveSummaries()
    }

    /// Archive a DynamicPet.
    func archive(_ pet: DynamicPet) {
        let archived = ArchivedDynamicPet(archiving: pet)
        let summary = ArchivedPetSummary(from: archived)

        saveDetail(archived, for: pet.id)
        summaries.insert(summary, at: 0)
        saveSummaries()
    }

    // MARK: - Public API: Delete

    /// Delete an archived pet.
    func delete(id: UUID) {
        summaries.removeAll { $0.id == id }
        saveSummaries()

        let url = Self.detailURL(for: id)
        try? FileManager.default.removeItem(at: url)

        detailCache.removeAll { $0.id == id }
    }

    // MARK: - Computed Properties

    /// Completed pets (not blown).
    var completedPets: [ArchivedPetSummary] {
        summaries.filter { !$0.isBlown }
    }

    /// Daily pet summaries.
    var dailySummaries: [ArchivedPetSummary] {
        summaries.filter { $0.petType == .daily }
    }

    /// Dynamic pet summaries.
    var dynamicSummaries: [ArchivedPetSummary] {
        summaries.filter { $0.petType == .dynamic }
    }
}

// MARK: - Private: Persistence

private extension ArchivedPetManager {
    func loadSummaries() {
        guard let data = try? Data(contentsOf: Self.summariesURL),
              let loaded = try? JSONDecoder().decode([ArchivedPetSummary].self, from: data) else {
            summaries = []
            return
        }
        summaries = loaded.sorted { $0.archivedAt > $1.archivedAt }
    }

    func saveSummaries() {
        guard let data = try? JSONEncoder().encode(summaries) else { return }
        try? data.write(to: Self.summariesURL)
    }

    func saveDetail<T: Encodable>(_ pet: T, for id: UUID) {
        try? FileManager.default.createDirectory(at: Self.archivedDirectoryURL, withIntermediateDirectories: true)

        let url = Self.detailURL(for: id)
        guard let data = try? JSONEncoder().encode(pet) else { return }
        try? data.write(to: url)
    }

    func loadFromDisk<T: Decodable>(id: UUID, as type: T.Type) -> T? {
        let url = Self.detailURL(for: id)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func cacheDetail(_ detail: ArchivedPetDetail) {
        // Remove if already cached (will be re-added at end)
        detailCache.removeAll { $0.id == detail.id }

        // Evict oldest if at capacity
        if detailCache.count >= maxCacheSize {
            detailCache.removeFirst()
        }

        // Add to end (most recent)
        detailCache.append(detail)
    }
}

// MARK: - Mock Data

extension ArchivedPetManager {
    static func mock(withSummaries: Bool = true) -> ArchivedPetManager {
        let manager = ArchivedPetManager()
        if withSummaries {
            manager.summaries = ArchivedPetSummary.mockList()
        }
        return manager
    }
}
