import Combine
import FamilyControls
import Foundation

@Observable
final class PetManager {
    // MARK: - Constants

    /// Pets younger than this are deleted instead of archived (not enough data to be useful).
    static let minimumArchiveDays = 3

    // MARK: - Dependencies

    var syncManager: SyncManager?

    // MARK: - Private Storage

    private var pet: Pet?
    private var authorizationCancellable: AnyCancellable?

    /// Whether a re-authorization prompt is pending (prevents spam on repeated .active cycles).
    var needsReauthorization = false

    /// Whether the pet needs app re-selection after cloud restore (invalid tokens from reinstall).
    /// Backed by SharedDefaults so it survives app restart.
    var needsAppReselection = false {
        didSet { SharedDefaults.needsAppReselection = needsAppReselection }
    }

    // MARK: - Public API

    /// Whether a pet currently exists (max one allowed).
    var hasPet: Bool { pet != nil }

    /// The current active pet (max one).
    var currentPet: Pet? { pet }

    // MARK: - Init

    init() {
        loadActivePet()
        detectAppReselectionIfNeeded()
        restoreMonitoringIfNeeded()
        observeAuthorizationStatus()
    }

    // MARK: - Create

    /// Creates a new pet (starts as blob). Returns nil if a pet already exists.
    @discardableResult
    func create(
        name: String,
        purpose: String?,
        preset: WindPreset = .default,
        limitedSources: [LimitedSource] = []
    ) -> Pet? {
        guard pet == nil else { return nil }

        let newPet = Pet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            preset: preset,
            limitedSources: limitedSources
        )
        pet = newPet
        saveActivePet()
        return newPet
    }

    // MARK: - Archive

    /// Archives the active pet, or deletes it if too young to be worth keeping.
    func archive(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // End active break first so it gets logged to SnapshotStore
        if SharedDefaults.isShieldActive {
            ShieldManager.shared.turnOff(success: true)
        }

        // Stop monitoring and clear all data
        ScreenTimeManager.shared.stopMonitoringAndClear()

        // Pets younger than minimum days are just deleted (not enough data to archive)
        guard currentPet.daysSinceCreation >= Self.minimumArchiveDays else {
            pet = nil
            saveActivePet()

            // Remove from cloud (too young to archive)
            Task { [syncManager] in
                await syncManager?.deleteActivePetFromCloud(petId: id)
            }
            return
        }

        let reason: ArchiveReason = currentPet.isBlown ? .blown
            : currentPet.isFullyEvolved ? .completed
            : .manual

        archivedPetManager.archive(currentPet, reason: reason)
        pet = nil
        saveActivePet()

        // Sync archived pet to cloud + delete active pet row
        Task { [syncManager, archivedPetManager] in
            if let archived = archivedPetManager.summaries.first,
               let detail = await archivedPetManager.loadDetail(for: archived) {
                await syncManager?.syncArchivedPet(detail, deletingActivePetId: id)
            }
        }
    }

    /// Blows away the pet and archives it.
    func blowAway(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }
        currentPet.blowAway()
        archive(id: id, using: archivedPetManager)
    }

    // MARK: - Authorization Check

    /// Observes FamilyControls authorization status reactively.
    /// `AuthorizationCenter.shared.authorizationStatus` starts as `.notDetermined` on cold launch
    /// and asynchronously resolves to the real value. We use `.dropFirst()` to skip the initial
    /// `.notDetermined` emission, which is not a real status change but just the default value
    /// before the framework loads the actual state. This prevents false revocation detection.
    private func observeAuthorizationStatus() {
        authorizationCancellable = AuthorizationCenter.shared.$authorizationStatus
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                #if DEBUG
                print("[PetManager] authorizationStatus changed = \(status)")
                #endif

                // Track successful authorization for revocation detection
                if status == .approved {
                    SharedDefaults.wasEverAuthorized = true
                    // Clear any pending reauthorization (fixes race: .notDetermined emits before .approved)
                    needsReauthorization = false
                    return
                }

                // Don't show separate ReauthorizationSheet if RestoreAppReselectionSheet
                // is already handling reauth (post-reinstall restore flow)
                guard let pet, !pet.isBlownAway, !needsReauthorization, !needsAppReselection else { return }

                // Detect revocation: .notDetermined after previous .approved means user revoked permission.
                // On cold start without prior authorization, wasEverAuthorized is false so we ignore.
                let isRevoked = (status == .notDetermined && SharedDefaults.wasEverAuthorized)
                    || status == .denied

                if isRevoked {
                    needsReauthorization = true
                }
            }
    }

    /// Call after the user successfully re-authorizes to resume normal operation.
    /// If `needsAppReselection` is true (post-reinstall restore), skips monitoring —
    /// tokens are invalid and RestoreReselectionSheet will handle app re-selection.
    func handleReauthorizationSuccess() {
        needsReauthorization = false
        if needsAppReselection {
            return
        }
        restoreMonitoringIfNeeded()
    }

    /// Call when the user declines re-authorization — marks the pet as blown away.
    /// Does NOT archive — the user sees the blow-away animation and archives manually.
    func handleReauthorizationDeclined() {
        needsReauthorization = false
        blowAwayCurrentPet(reason: .limitExceeded)
    }

    /// Marks the current pet as blown away (e.g. when violating a committed break).
    func blowAwayCurrentPet(reason: BlowAwayReason = .limitExceeded) {
        guard let pet = pet, !pet.isBlown else { return }

        // Cancel any active break/shield and stop monitoring
        ShieldManager.shared.clear()
        ScreenTimeManager.shared.stopMonitoring()

        // Set wind to 100% so blown away state looks correct visually
        SharedDefaults.monitoredWindPoints = 100

        pet.blowAway(reason: reason)
        saveActivePet()

        // Sync blown state immediately — critical state change
        Task { [syncManager] in
            await syncManager?.syncActivePet(petManager: self)
        }
    }

    // MARK: - Delete

    /// Removes the active pet without archiving.
    func delete(id: UUID) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // End active break first so it gets logged to SnapshotStore
        if SharedDefaults.isShieldActive {
            ShieldManager.shared.turnOff(success: true)
        }

        // Stop monitoring and clear all data before deleting
        ScreenTimeManager.shared.stopMonitoringAndClear()

        pet = nil
        saveActivePet()

        // Remove from cloud
        Task { [syncManager] in
            await syncManager?.deleteActivePetFromCloud(petId: id)
        }
    }

    // MARK: - Update Limited Sources

    /// Replaces the pet's limited sources and restarts monitoring.
    /// Wind is preserved — only the monitored tokens change.
    /// No-op if the new selection is identical to the current one (preserves change count).
    func updateLimitedSources(_ newSources: [LimitedSource], selection: FamilyActivitySelection) {
        guard let pet = pet, pet.canChangeLimitedSources else { return }

        // Skip if tokens are identical to current selection
        let currentTokens = (pet.applicationTokens, pet.categoryTokens, pet.webDomainTokens)
        let newTokens = (newSources.applicationTokens, newSources.categoryTokens, newSources.webDomainTokens)
        guard currentTokens != newTokens else { return }

        pet.updateLimitedSources(newSources)
        saveActivePet()

        // Persist selection for pre-populating the picker on next edit
        SharedDefaults.saveFamilyActivitySelection(selection)

        // Restart monitoring with new tokens (wind preserved)
        let limitSeconds = Int(pet.preset.minutesToBlowAway * 60)
        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            petName: pet.name,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }

    // MARK: - Post-Restore App Reselection

    /// Completes the post-restore app re-selection flow.
    /// Replaces invalid tokens with fresh ones and starts monitoring.
    /// Counts toward `limitedSourceChangesCount` (same as manual change).
    func handleAppReselectionComplete(_ newSources: [LimitedSource], selection: FamilyActivitySelection) {
        guard let pet else { return }

        pet.updateLimitedSources(newSources)
        saveActivePet()

        SharedDefaults.saveFamilyActivitySelection(selection)

        let limitSeconds = Int(pet.preset.minutesToBlowAway * 60)
        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            petName: pet.name,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )

        needsAppReselection = false

        Task { [syncManager] in
            await syncManager?.syncActivePet(petManager: self)
        }
    }

    enum AppReselectionAction {
        case blowAway, archive, delete
    }

    /// Handles exhausted app reselection — pet can't continue without monitoring.
    /// BlowAway only marks the pet as blown (user sees animation, archives manually).
    /// Caller must provide `archivedPetManager` for archive action.
    func handleAppReselectionExhausted(
        action: AppReselectionAction,
        using archivedPetManager: ArchivedPetManager? = nil
    ) {
        guard let pet else { return }
        needsAppReselection = false

        switch action {
        case .blowAway:
            blowAwayCurrentPet()
        case .archive:
            if let archivedPetManager {
                archive(id: pet.id, using: archivedPetManager)
            }
        case .delete:
            delete(id: pet.id)
        }
    }

    // MARK: - Sign Out Cleanup

    /// Clears all local pet data when the user signs out.
    /// Data remains in cloud for future restore. Does NOT delete from Supabase.
    func clearOnSignOut() {
        guard let pet else { return }

        if SharedDefaults.isShieldActive {
            ShieldManager.shared.turnOff(success: true)
        }
        ScreenTimeManager.shared.stopMonitoringAndClear()

        self.pet = nil
        saveActivePet()

        #if DEBUG
        print("[PetManager] Local pet cleared on sign out: \(pet.name)")
        #endif
    }

    // MARK: - Cloud Restore

    /// Restores an active pet from a cloud DTO. Sets windPoints in SharedDefaults.
    /// Returns the restored Pet, or nil if a local pet already exists.
    ///
    /// After restore, detects token validity:
    /// - Auth `.approved` (sign-out/sign-in, no reinstall) → tokens valid → starts monitoring
    /// - Auth `.notDetermined` (reinstall) → tokens invalid → sets `needsAppReselection`
    func restoreActivePet(from supabaseDTO: ActivePetSupabaseDTO) -> Pet? {
        guard pet == nil else { return nil }

        let dto = PetDTO(from: supabaseDTO)
        let restoredPet = Pet(from: dto)

        // Restore wind state to SharedDefaults (Pet reads windPoints from there)
        SharedDefaults.monitoredWindPoints = supabaseDTO.windPoints
        SharedDefaults.monitoredPetId = restoredPet.id

        pet = restoredPet
        saveActivePet()

        // Detect token validity based on authorization status
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            // No reinstall — tokens are still valid, start monitoring immediately
            if !restoredPet.isBlownAway, restoredPet.limitedSources.hasTokens {
                let limitSeconds = Int(restoredPet.preset.minutesToBlowAway * 60)
                ScreenTimeManager.shared.startMonitoring(
                    petId: restoredPet.id,
                    petName: restoredPet.name,
                    limitSeconds: limitSeconds,
                    limitedSources: restoredPet.limitedSources
                )
            }
        } else if !restoredPet.isBlownAway {
            // Reinstall — tokens invalid, need reselection after reauth
            needsAppReselection = true
        }

        return restoredPet
    }

    // MARK: - Save Trigger

    /// Call after mutating the pet to persist changes.
    func savePet() {
        saveActivePet()
    }

    // MARK: - Foreground Sync

    /// Checks for blow-away state when app returns to foreground.
    /// windPoints is computed from SharedDefaults, so no sync needed.
    func checkBlowAwayState() {
        let wasBlown = pet?.isBlown ?? false
        pet?.checkBlowAwayState()
        if pet?.isBlown == true && !wasBlown {
            saveActivePet()
        }
    }

    /// Refreshes daily usage stats from snapshots.
    /// Call on foreground return to populate usage history.
    func refreshDailyStats() {
        guard let pet = pet else { return }
        pet.dailyStats = SnapshotStore.shared.dailyUsageStats(petId: pet.id)
    }

    // MARK: - Post-Reinstall Detection

    /// Restores `needsAppReselection` from SharedDefaults on init.
    /// The flag is persisted so it survives app restarts — if the user closes the app
    /// without completing reselection, the sheet re-appears on next launch.
    private func detectAppReselectionIfNeeded() {
        needsAppReselection = SharedDefaults.needsAppReselection
    }

    // MARK: - Monitoring Restore

    /// Restores monitoring for existing pet after app restart/rebuild.
    /// DeviceActivityCenter schedules don't persist across app terminations,
    /// so we must re-register monitoring when the app launches.
    ///
    /// Skips restore when a break is active — monitoring is intentionally paused
    /// during breaks and will be restored by ShieldManager.turnOff via restartMonitoring.
    private func restoreMonitoringIfNeeded() {
        guard let pet = pet,
              !pet.isBlownAway,
              !pet.limitedSources.isEmpty,
              SharedDefaults.monitoredPetId == pet.id,
              !SharedDefaults.isShieldActive else {
            return
        }

        let limitSeconds = Int(pet.preset.minutesToBlowAway * 60)

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            petName: pet.name,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }

    /// Re-registers monitoring thresholds on foreground return.
    /// Uses restartMonitoring (no flag resets) to ensure thresholds are fresh
    /// even if another Family Controls app disrupted monitoring in the background.
    func ensureMonitoringActive() {
        guard let pet = pet,
              !pet.isBlownAway,
              !pet.limitedSources.isEmpty,
              SharedDefaults.monitoredPetId == pet.id,
              !SharedDefaults.isShieldActive else {
            return
        }

        ScreenTimeManager.shared.restartMonitoring()
    }

    // MARK: - Daily Reset

    /// Performs daily reset if needed (new day since last activity).
    /// Call this on app launch and foreground return.
    func performDailyResetIfNeeded() {
        guard let pet = pet, pet.windPoints.isZero, !pet.isBlownAway else { return }

        let today = SnapshotEvent.dateString(from: Date())
        let lastResetKey = "lastDailyReset_\(pet.id.uuidString)"

        if let lastReset = UserDefaults.standard.string(forKey: lastResetKey),
           lastReset == today {
            // Already reset today
            return
        }

        // Check if we have any usage from today - if not, don't reset yet
        // (user might be opening app for first time today)
        let todaySnapshots = SnapshotStore.shared.load(for: today)
        let hasSystemDayStart = todaySnapshots.contains { $0.eventType == .systemDayStart }

        if hasSystemDayStart {
            // New monitoring interval started, reset wind
            pet.resetWind()
            SnapshotLogging.logDailyReset(petId: pet.id, windPoints: 0)
            UserDefaults.standard.set(today, forKey: lastResetKey)
            saveActivePet()

            #if DEBUG
            print("[PetManager] Daily reset performed for pet \(pet.id)")
            #endif
        }
    }
}

// MARK: - Persistence (Active → SharedDefaults)

private extension PetManager {
    /// Loads the active pet from storage.
    func loadActivePet() {
        guard let data = SharedDefaults.data(forKey: DefaultsKeys.activePet),
              let dto = try? JSONDecoder().decode(PetDTO.self, from: data) else {
            return
        }
        pet = Pet(from: dto)
    }

    /// Saves the active pet to SharedDefaults.
    func saveActivePet() {
        if let pet = pet,
           let data = try? JSONEncoder().encode(PetDTO(from: pet)) {
            SharedDefaults.setData(data, forKey: DefaultsKeys.activePet)
        } else {
            SharedDefaults.removeObject(forKey: DefaultsKeys.activePet)
        }
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(withPet: Bool = true, phase: Int = 2, essence: Essence? = .plant, isBlownAway: Bool = false) -> PetManager {
        let manager = PetManager()
        if withPet {
            manager.pet = Pet.mock(phase: phase, essence: essence, isBlownAway: isBlownAway)
        }
        return manager
    }

    #if DEBUG
    /// Replaces the current pet with a mock pet for debug testing.
    func debugReplacePet(phase: Int = 3, essence: Essence? = .plant) {
        pet = Pet.mock(phase: phase, essence: essence)
        saveActivePet()
    }
    #endif
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}
