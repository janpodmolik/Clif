import Foundation
import Supabase
import UIKit

@Observable
@MainActor
final class SyncManager {

    // MARK: - Public State

    // internal setter needed for cross-file extensions (PetSync, Restore, Conflict, UserData)
    var isSyncing = false
    var lastSyncDate: Date?
    var lastError: Error?

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

    let minimumSyncInterval: TimeInterval = 30
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    var client: SupabaseClient { SupabaseConfig.client }

    var lastUserDataSyncAttempt: Date?

    var canSyncPet: Bool {
        lastSyncDate.map { Date().timeIntervalSince($0) > minimumSyncInterval } ?? true
    }

    var canSyncUserData: Bool {
        lastUserDataSyncAttempt.map { Date().timeIntervalSince($0) > minimumSyncInterval } ?? true
    }

    // MARK: - Auth Helper

    func currentUserId() async -> UUID? {
        try? await client.auth.session.user.id
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
}
