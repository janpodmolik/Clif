import SwiftUI

struct PetActiveDetailScreen: View {
    // MARK: - Pet Properties
    let petName: String
    let evolutionHistory: EvolutionHistory
    let totalDays: Int
    let purposeLabel: String?
    let windLevel: WindLevel
    let isBlownAway: Bool

    // MARK: - Screen Time Properties
    let todayUsedMinutes: Int
    let dailyLimitMinutes: Int

    // MARK: - Stats
    let fullStats: FullUsageStats

    // MARK: - Limited Apps
    let limitedAppCount: Int

    // MARK: - Evolution
    var daysUntilEvolution: Int? = 1

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onLimitedApps: () -> Void = {}
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
                            usedMinutes: todayUsedMinutes,
                            limitMinutes: dailyLimitMinutes
                        )
                    )

                    PetDetailHeader(
                        petName: petName,
                        mood: mood,
                        totalDays: totalDays,
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

                    UsageCard(stats: fullStats)

                    TrendMiniChart(stats: fullStats)

                    LimitedAppsBadge(
                        appCount: limitedAppCount,
                        onTap: onLimitedApps
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
                        colors: [
                            evolutionHistory.essence.themeColor,
                            evolutionHistory.essence.themeColor.opacity(0.7)
                        ],
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
                totalDays: 12,
                purposeLabel: "Social Media",
                windLevel: .medium,
                isBlownAway: false,
                todayUsedMinutes: 83,
                dailyLimitMinutes: 180,
                fullStats: .mock(days: 14),
                limitedAppCount: 12
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
                totalDays: 19,
                purposeLabel: "Social Media",
                windLevel: .low,
                isBlownAway: false,
                todayUsedMinutes: 25,
                dailyLimitMinutes: 90,
                fullStats: .mock(days: 19),
                limitedAppCount: 8,
                showOverviewActions: true
            )
        }
}
#endif

