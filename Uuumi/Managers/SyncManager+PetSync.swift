import Foundation
import Supabase

// MARK: - Pet Sync (active, archived, initial migration, delete)

extension SyncManager {

    // MARK: - Active Pet Sync

    /// Syncs the active pet to the cloud. Always runs (ignores debounce).
    func syncActivePet(petManager: PetManager) async {
        guard let pet = petManager.currentPet,
              let userId = await currentUserId() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let dto = PetLocalDTO(from: pet)
            let localBreakdowns = SnapshotStore.shared.computeDailyHourlyBreakdowns(petId: pet.id)

            // Merge local breakdowns with disk cache (which includes cloud history)
            let diskBreakdowns = DailyHourlyBreakdown.loadAllFromDisk()
            let hourlyPerDay = Self.mergeBreakdowns(base: diskBreakdowns, overlay: localBreakdowns)

            // Recompute aggregate from merged data (includes cloud history)
            let hourlyAggregate = HourlyAggregate.fromBreakdowns(hourlyPerDay)

            // Persist merged data locally before uploading (crash-safe ordering)
            storeHourlyPerDay(hourlyPerDay, petId: pet.id)
            SharedDefaults.setHourlyAggregate(hourlyAggregate, daysLimit: nil)

            let remoteDTO = ActivePetDTO(
                from: dto,
                userId: userId,
                windPoints: pet.windPoints,
                isBlownAway: pet.isBlownAway,
                hourlyAggregate: hourlyAggregate,
                hourlyPerDay: hourlyPerDay
            )

            try await client
                .from("active_pets")
                .upsert(remoteDTO, onConflict: "user_id")
                .execute()

            lastSyncDate = Date()
            lastError = nil

            #if DEBUG
            print("[SyncManager] Active pet synced successfully")
            #endif
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Active pet sync failed: \(error)")
            #endif
        }
    }

    /// Syncs the active pet only if debounce interval has passed.
    /// Skips sync when initial sync hasn't completed yet (conflict check / cloud restore)
    /// or when a pet conflict is pending (to avoid overwriting the cloud pet).
    func syncActivePetIfNeeded(petManager: PetManager) async {
        guard canSyncPet,
              pendingConflict == nil,
              UserDefaults.standard.bool(forKey: "hasCompletedInitialSync")
        else { return }
        await syncActivePet(petManager: petManager)
    }

    // MARK: - Archived Pet Sync

    /// Syncs an archived pet to the cloud. Inserts directly + optionally deletes active pet.
    func syncArchivedPet(_ archivedPet: ArchivedPet, deletingActivePetId: UUID? = nil) async {
        guard let userId = await currentUserId() else { return }

        do {
            let localBreakdowns = SnapshotStore.shared.computeDailyHourlyBreakdowns(petId: archivedPet.id)

            // Merge local breakdowns with disk cache (which includes cloud history)
            let diskBreakdowns = DailyHourlyBreakdown.loadAllFromDisk()
            let hourlyPerDay = Self.mergeBreakdowns(base: diskBreakdowns, overlay: localBreakdowns)

            let hourlyAggregate = HourlyAggregate.fromBreakdowns(hourlyPerDay)

            let remoteDTO = ArchivedPetDTO(
                from: archivedPet,
                userId: userId,
                hourlyAggregate: hourlyAggregate,
                hourlyPerDay: hourlyPerDay
            )

            // Insert archived pet (ON CONFLICT DO NOTHING handled by Supabase)
            try await client
                .from("archived_pets")
                .upsert(remoteDTO, ignoreDuplicates: true)
                .execute()

            // Delete active pet from cloud if provided
            if let activePetId = deletingActivePetId {
                try await client
                    .from("active_pets")
                    .delete()
                    .eq("id", value: activePetId.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            }

            #if DEBUG
            print("[SyncManager] Archived pet synced: \(archivedPet.name)")
            #endif
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Archived pet sync failed: \(error)")
            #endif
        }
    }

    // MARK: - Initial Sync (one-time migration of existing archived pets)

    /// Uploads all locally archived pets to the cloud. Runs once per device.
    func initialSyncIfNeeded(archivedPetManager: ArchivedPetManager) async {
        guard !UserDefaults.standard.bool(forKey: "hasCompletedInitialSync") else { return }
        guard await currentUserId() != nil else { return }

        let summaries = archivedPetManager.summaries
        guard !summaries.isEmpty else {
            UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")
            return
        }

        for summary in summaries {
            guard let detail = await archivedPetManager.loadDetail(for: summary) else { continue }
            await syncArchivedPet(detail)
        }

        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")

        #if DEBUG
        print("[SyncManager] Initial sync completed — \(summaries.count) archived pets uploaded")
        #endif
    }

    // MARK: - Hourly Per-Day Merge

    /// Merges two sets of breakdowns. Overlay entries win for dates that exist in both.
    static func mergeBreakdowns(
        base: [DailyHourlyBreakdown],
        overlay: [DailyHourlyBreakdown]
    ) -> [DailyHourlyBreakdown] {
        var merged: [String: DailyHourlyBreakdown] = [:]
        for breakdown in base {
            merged[breakdown.date] = breakdown
        }
        for breakdown in overlay {
            merged[breakdown.date] = breakdown
        }
        return merged.values.sorted { $0.date < $1.date }
    }

    // MARK: - Delete Active Pet from Cloud

    /// Removes the active pet row from the cloud (called when pet is deleted without archiving).
    func deleteActivePetFromCloud(petId: UUID) async {
        guard let userId = await currentUserId() else { return }

        do {
            try await client
                .from("active_pets")
                .delete()
                .eq("id", value: petId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[SyncManager] Active pet deleted from cloud: \(petId)")
            #endif
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Active pet cloud delete failed: \(error)")
            #endif
        }
    }
}
