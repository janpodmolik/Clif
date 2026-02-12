import Foundation
import Supabase

// MARK: - Pet Sync (active, archived, initial migration, delete)

extension SyncManager {

    // MARK: - Active Pet Sync

    /// Syncs the active pet to Supabase. Always runs (ignores debounce).
    func syncActivePet(petManager: PetManager) async {
        guard let pet = petManager.currentPet,
              let userId = await currentUserId() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let dto = PetDTO(from: pet)
            let hourlyAggregate = SnapshotStore.shared.computeHourlyAggregate()
            let hourlyPerDay = SnapshotStore.shared.computeDailyHourlyBreakdowns(petId: pet.id)

            let supabaseDTO = ActivePetSupabaseDTO(
                from: dto,
                userId: userId,
                windPoints: pet.windPoints,
                isBlownAway: pet.isBlownAway,
                hourlyAggregate: hourlyAggregate,
                hourlyPerDay: hourlyPerDay
            )

            try await client
                .from("active_pets")
                .upsert(supabaseDTO, onConflict: "user_id")
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

    /// Syncs an archived pet to Supabase. Inserts directly + optionally deletes active pet.
    func syncArchivedPet(_ archivedPet: ArchivedPet, deletingActivePetId: UUID? = nil) async {
        guard let userId = await currentUserId() else { return }

        do {
            let hourlyPerDay = SnapshotStore.shared.computeDailyHourlyBreakdowns(petId: archivedPet.id)

            let supabaseDTO = ArchivedPetSupabaseDTO(
                from: archivedPet,
                userId: userId,
                hourlyPerDay: hourlyPerDay
            )

            // Insert archived pet (ON CONFLICT DO NOTHING handled by Supabase)
            try await client
                .from("archived_pets")
                .upsert(supabaseDTO, ignoreDuplicates: true)
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

    /// Uploads all locally archived pets to Supabase. Runs once per device.
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

    // MARK: - Delete Active Pet from Cloud

    /// Removes the active pet row from Supabase (called when pet is deleted without archiving).
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
