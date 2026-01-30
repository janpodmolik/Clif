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
    @State private var showEssencePicker = false
    @State private var showLimitedApps = false
    @State private var showDeleteConfirmation = false

    private var themeColor: Color {
        pet.themeColor
    }

    /// canUseEssence for blob, canEvolve for evolved
    private var canProgress: Bool {
        pet.isBlob ? pet.canUseEssence : pet.canEvolve
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
                        NoEssenceCard {
                            // TODO: Navigate to inventory
                        }
                    } else {
                        EssenceInfoCard(evolutionHistory: pet.evolutionHistory)
                    }

                    EvolutionCarousel(
                        pet: pet,
                        windLevel: pet.windLevel,
                        isBlownAway: pet.isBlown,
                        canUseEssence: pet.canUseEssence
                    )

                    if !pet.isBlob {
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
                        TrendMiniChart(stats: pet.fullStats)
                    }

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { showLimitedApps = true }
                    )

                    if showOverviewActions {
                        ArchivedPetActionsCard(
                            isBlownAway: pet.isBlown,
                            themeColor: themeColor
                        ) { action in
                            switch action {
                            case .delete: showDeleteConfirmation = true
                            case .showOnHomepage: onAction(.showOnHomepage)
                            case .replay: onAction(.replay)
                            }
                        }
                    } else {
                        ActivePetActionsCard(
                            isBlob: pet.isBlob,
                            canProgress: canProgress,
                            daysUntilProgress: daysUntilProgress,
                            isBlownAway: pet.isBlown
                        ) { action in
                            switch action {
                            case .progress:
                                if pet.isBlob {
                                    showEssencePicker = true
                                } else {
                                    pet.evolve()
                                }
                            case .blowAway: onAction(.blowAway)
                            case .replay: onAction(.replay)
                            case .delete: showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showEssencePicker) {
                EssencePickerSheet { essence in
                    pet.applyEssence(essence)
                }
            }
            .sheet(isPresented: $showLimitedApps) {
                LimitedAppsSheet(sources: pet.limitedSources)
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeletePetSheet(
                    petName: pet.name,
                    showArchiveOption: true,
                    onArchive: {
                        petManager.archive(id: pet.id, using: archivedPetManager)
                        dismiss()
                    },
                    onDelete: {
                        petManager.delete(id: pet.id)
                        dismiss()
                    }
                )
            }
        }
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
}

#Preview("With Active Break") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mockWithBreak())
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mockBlob(name: "Blobby", canUseEssence: true))
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(pet: .mock(name: "Ivy", phase: 3, windPoints: 30), showOverviewActions: true)
        }
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}
#endif
