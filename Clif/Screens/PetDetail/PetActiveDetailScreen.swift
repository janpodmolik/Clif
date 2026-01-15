import SwiftUI

struct PetActiveDetailScreen: View {
    let pet: ActivePet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onLimitedApps: () -> Void = {}
    var onShowOnHomepage: () -> Void = {}

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
                    WeatherCard(windLevel: pet.windLevel, isBlownAway: pet.isBlown)

                    StatCardView(
                        stat: ScreenTimeStat(
                            usedMinutes: pet.todayUsedMinutes,
                            limitMinutes: pet.dailyLimitMinutes
                        )
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

                    LimitedAppsBadge(
                        appCount: pet.limitedAppCount,
                        onTap: onLimitedApps
                    )

                    if showOverviewActions {
                        overviewActions
                    } else {
                        PetDetailActions(
                            isBlob: pet.isBlob,
                            canProgress: canProgress,
                            daysUntilProgress: daysUntilProgress,
                            isBlownAway: pet.isBlown,
                            onProgress: pet.isBlob ? { showEssencePicker = true } : { pet.evolve() },
                            onBlowAway: onBlowAway,
                            onReplay: onReplay,
                            onDelete: onDelete
                        )
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

    @ViewBuilder
    private var overviewActions: some View {
        if pet.isBlown {
            overviewBlownAwayActions
        } else {
            overviewNormalActions
        }
    }

    private var overviewNormalActions: some View {
        HStack(spacing: 16) {
            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onShowOnHomepage) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text("Zobrazit")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(themeColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeColor.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }

    private var overviewBlownAwayActions: some View {
        HStack(spacing: 16) {
            Button(action: onReplay) {
                HStack(spacing: 6) {
                    Image(systemName: "memories")
                    Text("Replay")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview("PetActiveDetailDebug") {
    NavigationStack {
        PetActiveDetailScreenDebug()
    }
}



#Preview("Full Screen Modal") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(pet: .mock(name: "Fern", phase: 2, windLevel: .medium))
        }
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(pet: .mock(name: "Ivy", phase: 3, windLevel: .low), showOverviewActions: true)
        }
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(pet: .mockBlob(name: "Blobby", canUseEssence: true))
        }
}
#endif
