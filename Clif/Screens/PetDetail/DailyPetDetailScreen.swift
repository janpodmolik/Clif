import SwiftUI

struct DailyPetDetailScreen: View {
    let pet: DailyPet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onAction: (DailyPetDetailAction) -> Void = { _ in }

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DailyStatusCard(
                        windLevel: pet.windLevel,
                        stat: ScreenTimeStat(
                            usedMinutes: pet.todayUsedMinutes,
                            limitMinutes: pet.dailyLimitMinutes
                        ),
                        isBlownAway: pet.isBlown
                    )

                    PetDetailHeader(
                        petName: pet.name,
                        mood: mood,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.currentPhase,
                        purposeLabel: pet.purpose,
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

                    UsageCard(stats: pet.fullStats)

                    if pet.totalDays > 1 {
                        TrendMiniChart(stats: pet.fullStats)
                    }

                    LimitedAppsButton(
                        apps: pet.limitedApps,
                        categories: pet.limitedCategories,
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
#Preview("PetDetailDebug") {
    NavigationStack {
        PetDetailScreenDebug()
    }
}

#Preview("Full Screen Modal") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DailyPetDetailScreen(pet: .mock(name: "Fern", phase: 2, todayUsedMinutes: 60))
        }
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DailyPetDetailScreen(pet: .mock(name: "Ivy", phase: 3, todayUsedMinutes: 30), showOverviewActions: true)
        }
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DailyPetDetailScreen(pet: .mockBlob(name: "Blobby", canUseEssence: true))
        }
}
#endif
