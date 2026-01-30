import Foundation

@Observable
final class ArchivedPetManager {
    // MARK: - Public State

    /// All archived pet summaries, sorted by archivedAt (newest first).
    private(set) var summaries: [ArchivedPetSummary] = []

    /// Loading state for summaries.
    private(set) var isLoadingSummaries = false

    // MARK: - Private Cache (LRU, newest at end)

    private var detailCache: [ArchivedPet] = []
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
    func loadDetail(for summary: ArchivedPetSummary) async -> ArchivedPet? {
        if let cached = detailCache.first(where: { $0.id == summary.id }) {
            return cached
        }

        guard let detail = loadFromDisk(id: summary.id, as: ArchivedPet.self) else {
            return nil
        }

        await MainActor.run { cacheDetail(detail) }
        return detail
    }

    // MARK: - Public API: Archive

    /// Archive a Pet.
    func archive(_ pet: Pet) {
        let archived = ArchivedPet(archiving: pet)
        let summary = ArchivedPetSummary(from: archived)

        saveDetail(archived, for: pet.id)
        summaries.insert(summary, at: 0)
        saveSummaries()
    }

    // MARK: - Public API: Essence Records

    /// Build essence records for the collection carousel.
    func essenceRecords(currentPet: Pet?) -> [EssenceRecord] {
        Essence.allCases.compactMap { essence in
            let matchingArchived = summaries.filter { $0.essence == essence }

            let hasActivePet = currentPet?.essence == essence
            let petCount = matchingArchived.count + (hasActivePet ? 1 : 0)

            guard petCount > 0 else { return nil }

            let archivedBest = matchingArchived.map(\.currentPhase).max()

            let activePetPhase: Int? = {
                guard let pet = currentPet, pet.essence == essence else { return nil }
                return pet.currentPhase
            }()

            let bestPhase = [archivedBest, activePetPhase].compactMap { $0 }.max()

            return EssenceRecord(
                id: essence.rawValue,
                essence: essence,
                bestPhase: bestPhase,
                petCount: petCount
            )
        }
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

    func cacheDetail(_ detail: ArchivedPet) {
        detailCache.removeAll { $0.id == detail.id }

        if detailCache.count >= maxCacheSize {
            detailCache.removeFirst()
        }

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
