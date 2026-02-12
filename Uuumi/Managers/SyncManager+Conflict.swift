import Foundation
import Supabase

// MARK: - Pet Conflict Detection & Resolution

extension SyncManager {

    // MARK: - Pet Conflict Detection

    /// Checks if the cloud account has an active pet that conflicts with the local pet.
    /// Called when signing in with a local pet already present.
    func checkForPetConflict(
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager
    ) async {
        print("[SyncManager] checkForPetConflict called — isSyncing=\(isSyncing), hasPet=\(petManager.hasPet), pet=\(petManager.currentPet?.name ?? "nil"), pendingConflict=\(pendingConflict != nil), initialSync=\(UserDefaults.standard.bool(forKey: "hasCompletedInitialSync"))")

        guard pendingConflict == nil,
              petManager.hasPet,
              let localPet = petManager.currentPet,
              let userId = await currentUserId() else {
            print("[SyncManager] checkForPetConflict — guard failed, skipping")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch cloud active pet
            let activePetResponse: [ActivePetSupabaseDTO] = try await client
                .from("active_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            // Fetch cloud archived pets (needed for both paths)
            let archivedResponse: [ArchivedPetSupabaseDTO] = try await client
                .from("archived_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("archived_at", ascending: false)
                .execute()
                .value

            print("[SyncManager] Cloud has \(activePetResponse.count) active pet(s), local pet id=\(localPet.id)")

            if let cloudPet = activePetResponse.first.map(migrateIfNeeded) {
                if cloudPet.id == localPet.id {
                    // Same pet on both sides — no conflict, just sync archived pets
                    print("[SyncManager] Same pet on both sides (id=\(cloudPet.id)) — no conflict")
                    restoreArchivedPetsIfNeeded(archivedResponse, into: archivedPetManager)
                    let cloudArchivedIds = Set(archivedResponse.map(\.id))
                    await uploadLocalArchivedPetsIfNeeded(
                        cloudPetIds: cloudArchivedIds,
                        archivedPetManager: archivedPetManager
                    )
                    UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")
                    lastSyncDate = Date()
                } else {
                    // Different pet — real conflict, show resolution sheet
                    print("[SyncManager] CONFLICT: local=\(localPet.name) (id=\(localPet.id)) vs cloud=\(cloudPet.name) (id=\(cloudPet.id))")
                    pendingConflict = PetConflictData(
                        localPet: localPet,
                        cloudDTO: cloudPet,
                        cloudArchivedDTOs: archivedResponse
                    )
                    print("[SyncManager] pendingConflict set, value is nil: \(pendingConflict == nil)")
                }
            } else {
                // No cloud pet — no conflict, sync local pet up + restore archived
                print("[SyncManager] No cloud pet — syncing local pet up")
                restoreArchivedPetsIfNeeded(archivedResponse, into: archivedPetManager)
                let cloudArchivedIds = Set(archivedResponse.map(\.id))
                await uploadLocalArchivedPetsIfNeeded(
                    cloudPetIds: cloudArchivedIds,
                    archivedPetManager: archivedPetManager
                )
                UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")
                await syncActivePet(petManager: petManager)
            }

            lastError = nil
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Pet conflict check failed: \(error)")
            #endif
        }
    }

    // MARK: - Pet Conflict Resolution

    /// Resolves a pet conflict by keeping one pet and deleting the other.
    func resolveConflict(
        _ resolution: ConflictResolution,
        conflict: PetConflictData,
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager,
        essenceCatalogManager: EssenceCatalogManager
    ) async {
        guard await currentUserId() != nil else { return }

        isSyncing = true
        defer {
            isSyncing = false
            pendingConflict = nil
        }

        switch resolution {
        case .keepLocal:
            await resolveKeepLocal(
                conflict: conflict,
                petManager: petManager
            )
            // Merge user data: coins take max, essences are unioned
            await mergeUserDataOnConflict(essenceCatalogManager: essenceCatalogManager)

        case .keepCloud:
            await resolveKeepCloud(
                conflict: conflict,
                petManager: petManager
            )
            // Merge user data: coins take max, essences are unioned
            await mergeUserDataOnConflict(essenceCatalogManager: essenceCatalogManager)
        }

        // Restore cloud archived pets (in both cases)
        restoreArchivedPetsIfNeeded(conflict.cloudArchivedDTOs, into: archivedPetManager)

        // Upload local-only archived pets to cloud
        let cloudArchivedIds = Set(conflict.cloudArchivedDTOs.map(\.id))
        await uploadLocalArchivedPetsIfNeeded(
            cloudPetIds: cloudArchivedIds,
            archivedPetManager: archivedPetManager
        )

        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")
        lastSyncDate = Date()
    }

    /// Keep local pet → delete cloud pet + sync local up.
    private func resolveKeepLocal(
        conflict: PetConflictData,
        petManager: PetManager
    ) async {
        guard let userId = await currentUserId() else { return }
        let cloudDTO = conflict.cloudDTO

        do {
            try await client
                .from("active_pets")
                .delete()
                .eq("id", value: cloudDTO.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("[SyncManager] Cloud pet deleted: \(cloudDTO.name)")
            #endif
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Failed to delete cloud pet: \(error)")
            #endif
        }

        // Upload local pet to cloud
        await syncActivePet(petManager: petManager)
    }

    /// Keep cloud pet → delete local pet + restore cloud pet.
    private func resolveKeepCloud(
        conflict: PetConflictData,
        petManager: PetManager
    ) async {
        // Delete local pet (stops monitoring, nils pet)
        petManager.clearForConflictResolution()

        // Restore cloud pet using existing infrastructure
        let cloudDTO = conflict.cloudDTO
        let restoredPet = petManager.restoreActivePet(from: cloudDTO)

        // Restore hourly aggregate
        if let aggregate = cloudDTO.hourlyAggregate {
            SharedDefaults.hourlyAggregate = aggregate
        }

        // Store hourly per-day breakdowns
        if !cloudDTO.hourlyPerDay.isEmpty, let petId = restoredPet?.id {
            storeHourlyPerDay(cloudDTO.hourlyPerDay, petId: petId)
        }

        // Lock preset for today
        SharedDefaults.windPresetLockedForToday = true
        SharedDefaults.windPresetLockedDate = Date()
        SharedDefaults.isDayStartShieldActive = false

        #if DEBUG
        print("[SyncManager] Cloud pet restored after conflict: \(cloudDTO.name)")
        #endif
    }

    /// Merges local and cloud user data during conflict resolution.
    /// Coins take the higher value (safe against duplication), essences are unioned.
    /// After merging locally, uploads the merged result to cloud.
    private func mergeUserDataOnConflict(essenceCatalogManager: EssenceCatalogManager) async {
        guard let userId = await currentUserId() else { return }

        do {
            let response: [UserDataDTO] = try await client
                .from("user_data")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let cloudData = response.first.map(migrateUserDataIfNeeded) {
                let cloudPayload = cloudData.data
                let localCoins = SharedDefaults.coinsBalance

                // Coins: keep the higher value (safe — avoids duplicating coins)
                SharedDefaults.coinsBalance = max(localCoins, cloudPayload.coinsBalance)

                // Essences: union of both sets
                let cloudEssences = Set(cloudPayload.unlockedEssences.compactMap { Essence(rawValue: $0) })
                let merged = essenceCatalogManager.unlockedEssences.union(cloudEssences)
                essenceCatalogManager.restoreUnlocked(merged)

                #if DEBUG
                print("[SyncManager] Merged user data — coins: \(SharedDefaults.coinsBalance) (local: \(localCoins), cloud: \(cloudPayload.coinsBalance)), essences: \(merged.count)")
                #endif
            }
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] User data merge failed: \(error)")
            #endif
        }

        // Upload merged result to cloud
        await syncUserData(essenceCatalogManager: essenceCatalogManager)
    }
}
