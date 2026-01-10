import SwiftUI

struct PetDetailSheet: View {
    // MARK: - Pet Properties
    let petName: String
    let evolutionHistory: EvolutionHistory
    let streak: Int
    let purposeLabel: String?
    let windLevel: WindLevel
    let isBlownAway: Bool

    // MARK: - Screen Time Properties
    let usedMinutes: Int
    let limitMinutes: Int

    // MARK: - Stats
    let weeklyStats: BlockedAppsWeeklyStats

    // MARK: - Actions
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onSeeAllStats: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private var mood: Mood {
        Mood(from: windLevel)
    }

    private var canEvolve: Bool {
        evolutionHistory.canEvolve && !isBlownAway
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    WeatherCard(windLevel: windLevel)

                    PetDetailHeader(
                        petName: petName,
                        mood: mood,
                        streak: streak,
                        purposeLabel: purposeLabel
                    )

                    EvolutionCarousel(
                        currentPhase: evolutionHistory.currentPhase,
                        essence: evolutionHistory.essence,
                        mood: mood
                    )

                    EssenceOriginBadge(essence: evolutionHistory.essence)

                    EvolutionTimelineView(history: evolutionHistory)

                    StatCardView(
                        stat: ScreenTimeStat(
                            usedMinutes: usedMinutes,
                            limitMinutes: limitMinutes
                        )
                    )

                    BlockedAppsChart(
                        stats: weeklyStats,
                        onTap: onSeeAllStats
                    )

                    PetDetailActions(
                        canEvolve: canEvolve,
                        isBlownAway: isBlownAway,
                        onEvolve: onEvolve,
                        onBlowAway: onBlowAway,
                        onReplay: onReplay,
                        onDelete: onDelete
                    )
                }
                .padding()
            }
            .navigationTitle(petName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#if DEBUG
#Preview {
    Text("Tap to open")
        .sheet(isPresented: .constant(true)) {
            PetDetailSheet(
                petName: "Fern",
                evolutionHistory: EvolutionHistory(
                    createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                    essence: .plant,
                    events: [
                        EvolutionEvent(
                            fromPhase: 1,
                            toPhase: 2,
                            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        )
                    ]
                ),
                streak: 12,
                purposeLabel: "Social Media",
                windLevel: .medium,
                isBlownAway: false,
                usedMinutes: 83,
                limitMinutes: 180,
                weeklyStats: .mock()
            )
        }
}
#endif
