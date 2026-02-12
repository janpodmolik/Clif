import Foundation
import Supabase
import UIKit

@Observable
@MainActor
final class SyncManager {

    // MARK: - Public State

    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var lastError: Error?

    /// Set when a sign-in detects both a local pet and a cloud pet (different IDs).
    /// HomeScreen observes this to show PetConflictSheet.
    var pendingConflict: PetConflictData?

    /// Total coins from the last `claimPendingRewards()` call. ContentView observes
    /// this to trigger the coin reward animation; reset to 0 after consuming.
    var lastClaimedRewards: Int = 0

    enum ConflictResolution {
        case keepLocal
        case keepCloud
    }

    // MARK: - Private

    private let minimumSyncInterval: TimeInterval = 30
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var client: SupabaseClient { SupabaseConfig.client }

    private var lastUserDataSyncAttempt: Date?

    private var canSyncPet: Bool {
        lastSyncDate.map { Date().timeIntervalSince($0) > minimumSyncInterval } ?? true
    }

    private var canSyncUserData: Bool {
        lastUserDataSyncAttempt.map { Date().timeIntervalSince($0) > minimumSyncInterval } ?? true
    }

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

    // MARK: - Background Sync

    /// Wraps async work in a UIKit background task (~30s window).
    func syncInBackground(_ work: @escaping @Sendable @MainActor () async -> Void) {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        Task { @MainActor in
            await work()
            endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
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

    // MARK: - Restore from Cloud

    /// Restores active pet + archived pets from Supabase after a fresh install.
    /// Only runs when authenticated and no local pet exists.
    func restoreFromCloud(
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager
    ) async {
        guard !petManager.hasPet,
              let userId = await currentUserId() else { return }

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
        archivedPetManager: ArchivedPetManager
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

        case .keepCloud:
            await resolveKeepCloud(
                conflict: conflict,
                petManager: petManager
            )
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

    // MARK: - User Data Sync

    /// Uploads current local user data to Supabase (upsert on user_id).
    func syncUserData(essenceCatalogManager: EssenceCatalogManager) async {
        guard let userId = await currentUserId() else { return }

        do {
            let dto = UserDataDTO.fromLocal(
                userId: userId,
                essenceCatalogManager: essenceCatalogManager
            )

            try await client
                .from("user_data")
                .upsert(dto, onConflict: "user_id")
                .execute()

            lastUserDataSyncAttempt = Date()
            UserDefaults.standard.set(Date(), forKey: DefaultsKeys.lastUserDataSync)

            #if DEBUG
            print("[SyncManager] User data synced successfully")
            #endif
        } catch {
            lastUserDataSyncAttempt = Date()
            lastError = error
            #if DEBUG
            print("[SyncManager] User data sync failed: \(error)")
            #endif
        }
    }

    /// Syncs user data only if debounce interval has passed.
    func syncUserDataIfNeeded(essenceCatalogManager: EssenceCatalogManager) async {
        guard canSyncUserData,
              pendingConflict == nil,
              UserDefaults.standard.bool(forKey: "hasCompletedInitialSync")
        else { return }
        await syncUserData(essenceCatalogManager: essenceCatalogManager)
    }

    /// Restores user data from Supabase to local storage.
    /// Called during cloud restore (fresh install) or sign-in with existing account.
    func restoreUserData(essenceCatalogManager: EssenceCatalogManager) async {
        guard let userId = await currentUserId() else { return }

        do {
            let response: [UserDataDTO] = try await client
                .from("user_data")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            guard let cloudData = response.first.map(migrateUserDataIfNeeded) else {
                #if DEBUG
                print("[SyncManager] No cloud user data found — skipping restore")
                #endif
                return
            }

            let payload = cloudData.data

            // Freshness check: skip restore if local data is newer than cloud.
            // When editing data manually in Supabase, always update `updated_at` to now()
            // so that the change propagates to the app on next restore.
            let localSyncDate = UserDefaults.standard.object(forKey: DefaultsKeys.lastUserDataSync) as? Date
            let cloudIsNewer = localSyncDate.map { cloudData.updatedAt ?? .distantPast > $0 } ?? true

            if cloudIsNewer {
                // Tier 1
                SharedDefaults.coinsBalance = payload.coinsBalance

                let restoredEssences = Set(payload.unlockedEssences.compactMap { Essence(rawValue: $0) })
                essenceCatalogManager.restoreUnlocked(restoredEssences)

                SharedDefaults.limitSettings = payload.limitSettings

                #if DEBUG
                print("[SyncManager] User data restored — coins: \(payload.coinsBalance), essences: \(restoredEssences.count)")
                #endif
            } else {
                #if DEBUG
                print("[SyncManager] Local user data is newer — skipping restore, will upload instead")
                #endif
            }

            // If local was newer, push it to cloud to keep everything in sync
            if !cloudIsNewer {
                await syncUserData(essenceCatalogManager: essenceCatalogManager)
            }
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] User data restore failed: \(error)")
            #endif
        }
    }

    // MARK: - Pending Rewards

    /// Claims unclaimed rewards from Supabase, adds coins locally, and marks them as claimed.
    /// Returns the total coins claimed (0 if none).
    @discardableResult
    func claimPendingRewards() async -> Int {
        guard let userId = await currentUserId() else { return 0 }

        do {
            let unclaimed: [PendingRewardDTO] = try await client
                .from("pending_rewards")
                .select()
                .eq("user_id", value: userId.uuidString)
                .is("claimed_at", value: nil)
                .execute()
                .value

            guard !unclaimed.isEmpty else { return 0 }

            let total = unclaimed.reduce(0) { $0 + $1.amount }
            SharedDefaults.addCoins(total)

            // Mark all as claimed
            let claimedIds = unclaimed.map(\.id.uuidString)
            try await client
                .from("pending_rewards")
                .update(["claimed_at": Date().ISO8601Format()])
                .in("id", values: claimedIds)
                .execute()

            lastClaimedRewards = total

            #if DEBUG
            print("[SyncManager] Claimed \(unclaimed.count) pending reward(s): +\(total) coins")
            #endif

            return total
        } catch {
            lastError = error
            #if DEBUG
            print("[SyncManager] Claim pending rewards failed: \(error)")
            #endif
            return 0
        }
    }

    // MARK: - Sign-Out Cleanup

    /// Clears all sync-managed local data (settings, caches, disk files).
    /// Cloud data is preserved for future restore.
    func clearOnSignOut() {
        // User data
        SharedDefaults.coinsBalance = 0
        SharedDefaults.limitSettings = .default

        // Snapshot data & hourly aggregate cache
        SnapshotStore.shared.clearAll()
        for limit in SharedDefaults.supportedDaysLimits {
            SharedDefaults.setHourlyAggregate(nil, daysLimit: limit)
        }

        // Cloud-restored hourly breakdown files
        let hourlyPerDayURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("hourly_per_day")
        try? FileManager.default.removeItem(at: hourlyPerDayURL)

        // Sync state
        UserDefaults.standard.removeObject(forKey: DefaultsKeys.lastUserDataSync)
        UserDefaults.standard.removeObject(forKey: "hasCompletedInitialSync")
        pendingConflict = nil
    }

    // MARK: - Schema Migration

    /// Migrates a cloud DTO to the current schema version if needed.
    private func migrateIfNeeded(_ dto: ActivePetSupabaseDTO) -> ActivePetSupabaseDTO {
        switch dto.schemaVersion {
        case 1: return dto // current version
        // case 1: return migrateV1toV2(dto) // future migrations
        default: return dto
        }
    }

    /// Migrates cloud user data DTO to current schema version.
    private func migrateUserDataIfNeeded(_ dto: UserDataDTO) -> UserDataDTO {
        switch dto.schemaVersion {
        case 1: return dto
        default: return dto
        }
    }

    // MARK: - Helpers

    private func currentUserId() async -> UUID? {
        try? await client.auth.session.user.id
    }

    /// Restores archived pets from cloud DTOs + stores hourly data. Reusable helper.
    private func restoreArchivedPetsIfNeeded(
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
    private func uploadLocalArchivedPetsIfNeeded(
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
    private func storeHourlyPerDay(_ breakdowns: [DailyHourlyBreakdown], petId: UUID) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent("hourly_per_day")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileURL = directoryURL.appendingPathComponent("\(petId.uuidString).json")
        guard let data = try? JSONEncoder().encode(breakdowns) else { return }
        try? data.write(to: fileURL)
    }
}
