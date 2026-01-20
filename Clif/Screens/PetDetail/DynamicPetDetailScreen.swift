import SwiftUI

struct DynamicPetDetailScreen: View {
    let pet: DynamicPet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onAction: (DynamicPetDetailAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var showEssencePicker = false

    private var mood: Mood {
        pet.isBlown ? .blown : Mood(from: pet.windLevel)
    }

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
        guard pet.config.riseRate > 0 else { return nil }
        let remaining = (100 - pet.windPoints) / pet.config.riseRate
        return remaining > 0 ? remaining : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DynamicStatusCard(
                        windProgress: pet.windProgress,
                        windLevel: pet.windLevel,
                        config: pet.config,
                        isBlownAway: pet.isBlown,
                        activeBreak: pet.activeBreak,
                        currentWindPoints: pet.windPoints,
                        timeToBlowAway: timeToBlowAway,
                        onStartBreak: { onAction(.startBreak) },
                        onEndBreak: { onAction(.endBreak) }
                    )

                    PetDetailHeader(
                        petName: pet.name,
                        mood: mood,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.currentPhase,
                        purpose: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt,
                        modeInfo: PetModeInfo(from: pet)
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
                        mood: mood,
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
                        UsageCard(stats: pet.fullStats)
                    }

                    if pet.totalDays > 1 {
                        TrendMiniChart(stats: pet.fullStats)
                    }

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { onAction(.limitedApps) }
                    )

                    if showOverviewActions {
                        ArchivedPetActionsCard(
                            isBlownAway: pet.isBlown,
                            themeColor: themeColor
                        ) { action in
                            switch action {
                            case .delete: onAction(.delete)
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
                            case .delete: onAction(.delete)
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
        }
    }

}

#if DEBUG
#Preview("Dynamic Pet Detail") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Fern", phase: 2, windPoints: 45))
        }
}

#Preview("With Active Break") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mockWithBreak())
        }
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mockBlob(name: "Blobby", canUseEssence: true))
        }
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Ivy", phase: 3, windPoints: 30), showOverviewActions: true)
        }
}
#endif
