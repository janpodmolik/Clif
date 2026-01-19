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

                    LimitedAppsBadge(
                        appCount: pet.limitedAppCount,
                        onTap: { onAction(.limitedApps) }
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
                            onBlowAway: { onAction(.blowAway) },
                            onReplay: { onAction(.replay) },
                            onDelete: { onAction(.delete) }
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
            Button { onAction(.delete) } label: {
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

            Button { onAction(.showOnHomepage) } label: {
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
            Button { onAction(.replay) } label: {
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

            Button { onAction(.delete) } label: {
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
