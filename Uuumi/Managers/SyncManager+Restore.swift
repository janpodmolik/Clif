import Foundation
import Supabase

// MARK: - Restore from Cloud

extension SyncManager {

    /// Restores active pet + archived pets from the cloud after a fresh install.
    /// Only runs when authenticated and no local pet exists.
    func restoreFromCloud(
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager,
        skipMonitoring: Bool = false
    ) async {
        guard !petManager.hasPet, let userId = await currentUserId() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // 1. Restore active pet
            let activePetResponse: [ActivePetDTO] = try await client
                .from("active_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let cloudPet = activePetResponse.first.map(migrateIfNeeded) {
                let restoredPet = petManager.restoreActivePet(from: cloudPet, skipMonitoring: skipMonitoring)

                // Mark today's preset as selected — restored pet already has one
                SharedDefaults.todaySelectedPreset = cloudPet.preset
                SharedDefaults.lastDayResetDate = Calendar.current.startOfDay(for: Date())
                SharedDefaults.isDayStartShieldActive = false

                #if DEBUG
                print("[SyncManager] Active pet restored: \(cloudPet.name)")
                #endif
            }

            // 2. Restore archived pets
            let archivedResponse: [ArchivedPetDTO] = try await client
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

    // MARK: - Welcome Back (Reinstall Detection)

    /// Checks if the cloud account has an active pet when the app was reinstalled
    /// (Keychain token survived but onboarding was wiped). If found, sets `pendingWelcomeBack`
    /// so ContentView can show WelcomeBackSheet instead of OnboardingView.
    /// If no cloud pet exists, falls back to standard new-user restore flow.
    func checkForWelcomeBack(
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager,
        essenceCatalogManager: EssenceCatalogManager
    ) async {
        guard !petManager.hasPet, let userId = await currentUserId() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let activePetResponse: [ActivePetDTO] = try await client
                .from("active_pets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let cloudPet = activePetResponse.first.map(migrateIfNeeded) {
                // Cloud pet found — show Welcome Back sheet
                pendingWelcomeBack = cloudPet
                #if DEBUG
                print("[SyncManager] Reinstall detected — cloud pet found: \(cloudPet.name)")
                #endif
            } else {
                // No cloud pet — treat as a brand new user, do standard restore
                await restoreUserData(essenceCatalogManager: essenceCatalogManager)
                await restoreFromCloud(petManager: petManager, archivedPetManager: archivedPetManager)
                #if DEBUG
                print("[SyncManager] Reinstall detected — no cloud pet, standard restore")
                #endif
            }
        } catch {
            lastError = error
            // On error, fall back to standard restore so user isn't stuck
            await restoreUserData(essenceCatalogManager: essenceCatalogManager)
            await restoreFromCloud(petManager: petManager, archivedPetManager: archivedPetManager)
            #if DEBUG
            print("[SyncManager] Welcome back check failed: \(error)")
            #endif
        }
    }

    /// Resolves the Welcome Back sheet action chosen by the user.
    func resolveWelcomeBack(
        _ action: WelcomeBackAction,
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager,
        essenceCatalogManager: EssenceCatalogManager
    ) async {
        guard let cloudPet = pendingWelcomeBack,
              let userId = await currentUserId() else {
            pendingWelcomeBack = nil
            return
        }

        isSyncing = true
        defer {
            isSyncing = false
            pendingWelcomeBack = nil
        }

        switch action {
        case .continueWithPet:
            // Restore user data + active pet from cloud, skip onboarding.
            // Skip monitoring — tokens from cloud are invalid after reinstall.
            // ContentView will call handleAppReselectionComplete with fresh tokens.
            await restoreUserData(essenceCatalogManager: essenceCatalogManager)
            await restoreFromCloud(petManager: petManager, archivedPetManager: archivedPetManager, skipMonitoring: true)

        case .archivePet:
            await resolveWelcomeBackArchive(
                cloudPet: cloudPet,
                userId: userId,
                petManager: petManager,
                archivedPetManager: archivedPetManager,
                essenceCatalogManager: essenceCatalogManager
            )

        case .deletePet:
            await resolveWelcomeBackDelete(
                cloudPet: cloudPet,
                userId: userId,
                archivedPetManager: archivedPetManager,
                essenceCatalogManager: essenceCatalogManager
            )
        }

        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSync")
        lastSyncDate = Date()
        lastError = nil
    }

    // MARK: - Helpers

    /// Restores archived pets from cloud DTOs. Reusable helper.
    func restoreArchivedPetsIfNeeded(
        _ dtos: [ArchivedPetDTO],
        into archivedPetManager: ArchivedPetManager
    ) {
        guard !dtos.isEmpty else { return }
        archivedPetManager.restoreArchivedPets(from: dtos)
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

    // MARK: - Welcome Back Helpers

    private func resolveWelcomeBackArchive(
        cloudPet: ActivePetDTO,
        userId: UUID,
        petManager: PetManager,
        archivedPetManager: ArchivedPetManager,
        essenceCatalogManager: EssenceCatalogManager
    ) async {
        let evolutionHistory = EvolutionHistory(from: cloudPet.evolutionHistory)
        let preset = WindPreset(rawValue: cloudPet.preset) ?? .balanced

        let archivedPet = ArchivedPet(
            id: cloudPet.id,
            name: cloudPet.name,
            evolutionHistory: evolutionHistory,
            purpose: cloudPet.purpose,
            archivedAt: Date(),
            archiveReason: .manual,
            dailyStats: cloudPet.dailyStats,
            breakHistory: cloudPet.breakHistory,
            peakWindPoints: cloudPet.windPoints,
            totalBreakMinutes: cloudPet.breakHistory.reduce(0) { acc, breakRecord in
                acc + breakRecord.endedAt.timeIntervalSince(breakRecord.startedAt) / 60
            },
            totalWindDecreased: cloudPet.breakHistory.reduce(0) { $0 + $1.windDecreased },
            preset: preset
        )

        archivedPetManager.archiveExisting(archivedPet)
        await syncArchivedPet(archivedPet, deletingActivePetId: cloudPet.id)

        let archivedResponse: [ArchivedPetDTO] = (try? await client
            .from("archived_pets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("archived_at", ascending: false)
            .execute()
            .value) ?? []
        restoreArchivedPetsIfNeeded(archivedResponse, into: archivedPetManager)

        await restoreUserData(essenceCatalogManager: essenceCatalogManager)

        #if DEBUG
        print("[SyncManager] Welcome back — cloud pet archived: \(cloudPet.name)")
        #endif
    }

    private func resolveWelcomeBackDelete(
        cloudPet: ActivePetDTO,
        userId: UUID,
        archivedPetManager: ArchivedPetManager,
        essenceCatalogManager: EssenceCatalogManager
    ) async {
        await deleteActivePetFromCloud(petId: cloudPet.id)

        let archivedResponse: [ArchivedPetDTO] = (try? await client
            .from("archived_pets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("archived_at", ascending: false)
            .execute()
            .value) ?? []
        restoreArchivedPetsIfNeeded(archivedResponse, into: archivedPetManager)

        await restoreUserData(essenceCatalogManager: essenceCatalogManager)

        #if DEBUG
        print("[SyncManager] Welcome back — cloud pet deleted: \(cloudPet.name)")
        #endif
    }
}
