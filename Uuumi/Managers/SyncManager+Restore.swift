import Foundation
import Supabase

// MARK: - Restore from Cloud

extension SyncManager {

    /// Restores active pet + archived pets from Supabase after a fresh install.
    /// Only runs when authenticated and no local pet exists.
    func restoreFromCloud(
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager
    ) async {
        guard !petManager.hasPet, let userId = await currentUserId() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // 1. Restore active pet
            let activePetResponse: [ActivePetSupabaseDTO] = try await client
                .from("active_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let cloudPet = activePetResponse.first.map(migrateIfNeeded) {
                let restoredPet = petManager.restoreActivePet(from: cloudPet)

                // Restore hourly aggregate to SharedDefaults (for DailyPatternCard)
                if let aggregate = cloudPet.hourlyAggregate {
                    SharedDefaults.hourlyAggregate = aggregate
                }

                // Store hourly per-day breakdowns locally (for DayDetailSheet fallback)
                if !cloudPet.hourlyPerDay.isEmpty, let petId = restoredPet?.id {
                    storeHourlyPerDay(cloudPet.hourlyPerDay, petId: petId)
                }

                // Lock preset for today — restored pet already has a preset,
                // prevent DailyPresetPicker from showing (which would reset wind)
                SharedDefaults.windPresetLockedForToday = true
                SharedDefaults.windPresetLockedDate = Date()
                SharedDefaults.isDayStartShieldActive = false

                #if DEBUG
                print("[SyncManager] Active pet restored: \(cloudPet.name)")
                #endif
            }

            // 2. Restore archived pets
            let archivedResponse: [ArchivedPetSupabaseDTO] = try await client
                .from("archived_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("archived_at", ascending: false)
                .execute()
                .value

            restoreArchivedPetsIfNeeded(archivedResponse, into: archivedPetManager)

            // 3. Upload local-only archived pets to cloud (local → cloud)
            let cloudArchivedIds = Set(archivedResponse.map(\.id))
            await uploadLocalArchivedPetsIfNeeded(
                cloudPetIds: cloudArchivedIds,
                archivedPetManager: archivedPetManager
            )

            #if DEBUG
            if !archivedResponse.isEmpty {
                print("[SyncManager] Restored \(archivedResponse.count) archived pets")
            }
            #endif

            // Mark initial sync as completed (cloud data is authoritative after restore)
            UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")

            lastSyncDate = Date()
            lastError = nil

            #if DEBUG
            print("[SyncManager] Cloud restore completed")
            #endif
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Cloud restore failed: \(error)")
            #endif
        }
    }

    // MARK: - Helpers

    /// Restores archived pets from cloud DTOs + stores hourly data. Reusable helper.
    func restoreArchivedPetsIfNeeded(
        _ dtos: [ArchivedPetSupabaseDTO],
        into archivedPetManager: ArchivedPetManager
    ) {
        guard !dtos.isEmpty else { return }
        archivedPetManager.restoreArchivedPets(from: dtos)
        for dto in dtos where !dto.hourlyPerDay.isEmpty {
            storeHourlyPerDay(dto.hourlyPerDay, petId: dto.id)
        }
    }

    /// Uploads local archived pets that don't exist in cloud. Called after cloud→local restore.
    func uploadLocalArchivedPetsIfNeeded(
        cloudPetIds: Set<UUID>,
        archivedPetManager: ArchivedPetManager
    ) async {
        let localOnly = archivedPetManager.summaries.filter { !cloudPetIds.contains($0.id) }
        guard !localOnly.isEmpty else { return }

        for summary in localOnly {
            guard let detail = await archivedPetManager.loadDetail(for: summary) else { continue }
            await syncArchivedPet(detail)
        }

        #if DEBUG
        print("[SyncManager] Uploaded \(localOnly.count) local-only archived pets to cloud")
        #endif
    }

    /// Stores hourly per-day breakdowns to a local JSON file for DayDetailSheet fallback.
    func storeHourlyPerDay(_ breakdowns: [DailyHourlyBreakdown], petId: UUID) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent("hourly_per_day")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileURL = directoryURL.appendingPathComponent("\(petId.uuidString).json")
        guard let data = try? JSONEncoder().encode(breakdowns) else { return }
        try? data.write(to: fileURL)
    }
}
