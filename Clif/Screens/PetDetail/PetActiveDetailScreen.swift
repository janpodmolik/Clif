import SwiftUI

struct PetActiveDetailScreen: View {
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

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onSeeAllStats: () -> Void = {}
    var onBlockedApps: () -> Void = {}
    var onShowOnHomepage: () -> Void = {}

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
                        dailyLimitMinutes: limitMinutes,
                        onTap: onSeeAllStats
                    )

                    BlockedAppsBadge(
                        appCount: blockedAppCount,
                        onTap: onBlockedApps
                    )

                    if showOverviewActions {
                        overviewActions
                    } else {
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

    private var overviewActions: some View {
        HStack {
            Spacer()

            Button(action: onShowOnHomepage) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text("Zobrazit na homepage")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [evolutionHistory.essence.themeColor, evolutionHistory.essence.themeColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PetActiveDetailScreenDebug()
    }
}
#endif


#if DEBUG
#Preview("Full Screen Modal") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(
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

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(
                petName: "Ivy",
                evolutionHistory: EvolutionHistory(
                    createdAt: Calendar.current.date(byAdding: .day, value: -19, to: Date())!,
                    essence: .plant,
                    events: [
                        EvolutionEvent(
                            fromPhase: 1,
                            toPhase: 2,
                            date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!
                        ),
                        EvolutionEvent(
                            fromPhase: 2,
                            toPhase: 3,
                            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
                        )
                    ]
                ),
                streak: 19,
                purposeLabel: "Social Media",
                windLevel: .low,
                isBlownAway: false,
                usedMinutes: 25,
                limitMinutes: 90,
                weeklyStats: .mock(),
                blockedAppCount: 8,
                showOverviewActions: true
            )
        }
}
#endif
