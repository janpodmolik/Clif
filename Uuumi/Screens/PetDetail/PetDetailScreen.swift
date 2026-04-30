import SwiftUI

struct PetDetailScreen: View {
    let pet: Pet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onAction: (PetDetailAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(StoreManager.self) private var storeManager
    @State private var showLimitedApps = false
    @State private var showPremiumSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showArchiveConfirmation = false
    @State private var showWindNotCalmAlert = false
    @State private var showBreakTypePicker = false

    /// canUseEssence for blob, canEvolve for evolved
    private var canProgress: Bool {
        pet.isBlob ? pet.canUseEssence : pet.canEvolve
    }

    /// Can archive early: has essence, not fully evolved, not blown, 3+ days old
    private var canArchiveEarly: Bool {
        !pet.isBlob && !pet.isFullyEvolved && !pet.isBlown
            && pet.daysSinceCreation >= PetManager.minimumArchiveDays
    }

    /// daysUntilEssence for blob, daysUntilEvolution for evolved
    private var daysUntilProgress: Int? {
        pet.isBlob ? pet.daysUntilEssence : pet.daysUntilEvolution
    }

    /// Minutes remaining until wind reaches 100% (blow away)
    private var timeToBlowAway: Double? {
        guard pet.preset.riseRate > 0 else { return nil }
        let remaining = (100 - pet.windPoints) / pet.preset.riseRate
        return remaining > 0 ? remaining : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatusCard(
                        windProgress: pet.windProgress,
                        windLevel: pet.windLevel,
                        preset: pet.preset,
                        isBlownAway: pet.isBlown,
                        activeBreak: pet.activeBreak,
                        currentWindPoints: pet.windPoints,
                        timeToBlowAway: timeToBlowAway
                    )

                    PetDetailHeader(
                        petName: pet.name,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.currentPhase,
                        purpose: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt
                    )

                    if pet.isBlob {
                        NoEssenceCard()
                    } else {
                        EssenceInfoCard(evolutionHistory: pet.evolutionHistory)
                    }

                    EvolutionCarousel(
                        pet: pet,
                        canUseEssence: pet.canUseEssence
                    )

                    if !pet.isBlob && !pet.hasUnknownEssence {
                        EvolutionTimelineView(
                            history: pet.evolutionHistory,
                            canEvolve: canProgress,
                            daysUntilEvolution: daysUntilProgress
                        )
                    }

                    if !pet.dailyStats.isEmpty {
                        DayByDayUsageCard(
                            stats: pet.fullStats,
                            petId: pet.id,
                            limitMinutes: Int(pet.preset.minutesToBlowAway)
                        )
                    }

                    if pet.totalDays > 1 {
                        if storeManager.isPremium {
                            TrendMiniChart(stats: pet.fullStats)
                        } else {
                            trendLockedCard
                        }
                    }

                    if !pet.isBlown {
                        LimitedAppsButton(
                            sources: pet.limitedSources,
                            onTap: { showLimitedApps = true }
                        )
                    }

                    if showOverviewActions {
                        OverviewPetActionsCard(
                            isBlownAway: pet.isBlown
                        ) { action in
                            switch action {
                            case .delete: showDeleteConfirmation = true
                            case .showOnHomepage: onAction(.showOnHomepage)
                            }
                        }
                    } else {
                        ActivePetActionsCard(
                            isBlob: pet.isBlob,
                            isFullyEvolved: pet.isFullyEvolved && !pet.isBlown,
                            canProgress: canProgress,
                            canArchiveEarly: canArchiveEarly,
                            isBlownAway: pet.isBlown
                        ) { action in
                            switch action {
                            case .progress:
                                guard pet.windLevel == .none else {
                                    showWindNotCalmAlert = true
                                    return
                                }
                                onAction(.progress)
                                dismiss()
                            case .blowAway: onAction(.blowAway)
                            case .replay:
                                onAction(.replay)
                            case .delete: showDeleteConfirmation = true
                            case .archive:
                                guard pet.windLevel == .none else {
                                    showWindNotCalmAlert = true
                                    return
                                }
                                if pet.isFullyEvolved {
                                    showArchiveConfirmation = true
                                } else {
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLimitedApps) {
                LimitedAppsSheet(
                    sources: pet.limitedSources,
                    changeState: showOverviewActions ? nil : pet.limitedSourceChangeState,
                    activeBreakType: pet.activeBreak?.type,
                    onEdit: showOverviewActions ? nil : { selection in
                        let newSources = LimitedSource.from(selection)
                        petManager.updateLimitedSources(newSources, selection: selection)
                        analytics.send(.limitedAppsChanged(appCount: newSources.count))
                    },
                    onEndFreeBreak: showOverviewActions ? nil : {
                        ShieldManager.shared.turnOff(success: true)
                    }
                )
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeletePetSheet(
                    petName: pet.name,
                    showArchiveOption: pet.daysSinceCreation >= PetManager.minimumArchiveDays,
                    onArchive: {
                        onAction(.archive)
                        dismiss()
                    },
                    onDelete: {
                        petManager.delete(id: pet.id)
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showArchiveConfirmation) {
                SuccessArchiveSheet(
                    petName: pet.name,
                    onArchive: {
                        onAction(.archive)
                        dismiss()
                    }
                )
            }
            .windNotCalmSheet(isPresented: $showWindNotCalmAlert, onStartBreak: {
                showBreakTypePicker = true
            })
            .sheet(isPresented: $showBreakTypePicker) {
                BreakTypePicker(
                    onSelectFree: {
                        analytics.sendBreakStarted(type: "free")
                        ShieldManager.shared.turnOn(breakType: .free, committedMode: nil)
                    },
                    onConfirmCommitted: { mode in
                        analytics.sendBreakStarted(type: "committed", duration: mode.durationSeconds.map { Int($0 / 60) })
                        ShieldManager.shared.turnOn(breakType: .committed, committedMode: mode)
                    }
                )
            }
            .dismissButton()
            .premiumSheet(isPresented: $showPremiumSheet, source: .petDetailTrend)
        }
    }

    // MARK: - Premium Locked

    private var trendLockedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("See how your habits evolve over time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PremiumButton("Unlock Trend", style: .inline) { showPremiumSheet = true }
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview("Pet Detail") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mock(name: "Fern", phase: 2, windPoints: 45))
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(StoreManager.mock())
}

#Preview("With Active Break") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mockWithBreak())
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(StoreManager.mock())
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mockBlob(name: "Blobby", canUseEssence: true))
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(StoreManager.mock())
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mock(name: "Ivy", phase: 3, windPoints: 30), showOverviewActions: true)
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(StoreManager.mock())
}
#endif
