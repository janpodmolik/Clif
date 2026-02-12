import Foundation
import Supabase

// MARK: - User Data Sync, Rewards & Schema Migration

extension SyncManager {

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

    // MARK: - Schema Migration

    /// Migrates a cloud DTO to the current schema version if needed.
    func migrateIfNeeded(_ dto: ActivePetSupabaseDTO) -> ActivePetSupabaseDTO {
        switch dto.schemaVersion {
        case 1: return dto // current version
        // case 1: return migrateV1toV2(dto) // future migrations
        default: return dto
        }
    }

    /// Migrates cloud user data DTO to current schema version.
    func migrateUserDataIfNeeded(_ dto: UserDataDTO) -> UserDataDTO {
        switch dto.schemaVersion {
        case 1: return dto
        default: return dto
        }
    }
}
