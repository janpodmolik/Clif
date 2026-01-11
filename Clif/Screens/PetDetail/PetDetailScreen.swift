import SwiftUI

struct PetDetailScreen: View {
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

    // MARK: - Blocked Apps
    let blockedAppCount: Int

    // MARK: - Evolution
    var daysUntilEvolution: Int? = 1

    // MARK: - Actions
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onSeeAllStats: () -> Void = {}
    var onBlockedApps: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private var mood: Mood {
        isBlownAway ? .blown : Mood(from: windLevel)
    }

    private var canEvolve: Bool {
        evolutionHistory.canEvolve && !isBlownAway
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    WeatherCard(windLevel: windLevel, isBlownAway: isBlownAway)

                    StatCardView(
                        stat: ScreenTimeStat(
                            usedMinutes: usedMinutes,
                            limitMinutes: limitMinutes
                        )
                    )
                    
                    PetDetailHeader(
                        petName: petName,
                        mood: mood,
                        streak: streak,
                        evolutionPhase: evolutionHistory.currentPhase,
                        purposeLabel: purposeLabel
                    )

                    EvolutionCarousel(
                        currentPhase: evolutionHistory.currentPhase,
                        essence: evolutionHistory.essence,
                        mood: mood,
                        isBlownAway: isBlownAway,
                        themeColor: evolutionHistory.essence.themeColor
                    )

                    EvolutionTimelineView(
                        history: evolutionHistory,
                        blownAt: evolutionHistory.blownAt,
                        canEvolve: canEvolve,
                        daysUntilEvolution: daysUntilEvolution
                    )

                    BlockedAppsChart(
                        stats: weeklyStats,
                        themeColor: evolutionHistory.essence.themeColor,
                        blownDate: evolutionHistory.blownAt,
                        onTap: onSeeAllStats
                    )

                    BlockedAppsBadge(
                        appCount: blockedAppCount,
                        onTap: onBlockedApps
                    )

                    PetDetailActions(
                        canEvolve: canEvolve,
                        daysUntilEvolution: daysUntilEvolution,
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
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PetDetailScreenDebug()
    }
}
#endif


#if DEBUG
#Preview("Full Screen Modal") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetDetailScreen(
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
                weeklyStats: .mock(),
                blockedAppCount: 12
            )
        }
}
#endif
