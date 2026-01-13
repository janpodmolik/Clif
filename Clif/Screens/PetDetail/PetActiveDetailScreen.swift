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

    // MARK: - Evolution & Essence
    var canProgress: Bool = false      // canUseEssence for blob, canEvolve for evolved
    var daysUntilProgress: Int? = nil  // daysUntilEssence for blob, daysUntilEvolution for evolved

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onEvolve: () -> Void = {}
    var onBlowAway: () -> Void = {}
    var onReplay: () -> Void = {}
    var onDelete: () -> Void = {}
    var onLimitedApps: () -> Void = {}
    var onShowOnHomepage: () -> Void = {}
    var onEssenceSelected: (Essence) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var showEssencePicker = false

    private var mood: Mood {
        isBlownAway ? .blown : Mood(from: windLevel)
    }

    private var isBlob: Bool {
        evolutionHistory.isBlob
    }

    private var themeColor: Color {
        evolutionHistory.essence.map { EvolutionPath.path(for: $0).themeColor } ?? .secondary
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
                        themeColor: themeColor
                    )

                    EvolutionTimelineView(
                        history: evolutionHistory,
                        blownAt: evolutionHistory.blownAt,
                        canEvolve: !isBlob && canProgress,
                        daysUntilEvolution: isBlob ? nil : daysUntilProgress
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
                            isBlob: isBlob,
                            canProgress: canProgress,
                            daysUntilProgress: daysUntilProgress,
                            isBlownAway: isBlownAway,
                            onProgress: isBlob ? { showEssencePicker = true } : onEvolve,
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
            .sheet(isPresented: $showEssencePicker) {
                EssencePickerSheet { essence in
                    onEssenceSelected(essence)
                }
            }
        }
    }

    @ViewBuilder
    private var overviewActions: some View {
        if isBlownAway {
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

#Preview("Overview Blown Away") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(
                petName: "Dusty",
                evolutionHistory: EvolutionHistory(
                    createdAt: Calendar.current.date(byAdding: .day, value: -25, to: Date())!,
                    essence: .plant,
                    events: [
                        EvolutionEvent(
                            fromPhase: 1,
                            toPhase: 2,
                            date: Calendar.current.date(byAdding: .day, value: -18, to: Date())!
                        ),
                        EvolutionEvent(
                            fromPhase: 2,
                            toPhase: 3,
                            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!
                        )
                    ],
                    blownAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
                ),
                totalDays: 25,
                purposeLabel: "Gaming",
                windLevel: .high,
                isBlownAway: true,
                todayUsedMinutes: 0,
                dailyLimitMinutes: 60,
                fullStats: .mock(days: 25),
                limitedAppCount: 5,
                showOverviewActions: true
            )
        }
}

#Preview("Blob - Day 1") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(
                petName: "Blobby",
                evolutionHistory: EvolutionHistory(
                    createdAt: Date(),
                    essence: nil
                ),
                totalDays: 0,
                purposeLabel: "Focus",
                windLevel: .none,
                isBlownAway: false,
                todayUsedMinutes: 15,
                dailyLimitMinutes: 120,
                fullStats: .mock(days: 1),
                limitedAppCount: 5,
                canProgress: false,
                daysUntilProgress: 1
            )
        }
}

#Preview("Blob - Ready for Essence") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            PetActiveDetailScreen(
                petName: "Blobby",
                evolutionHistory: EvolutionHistory(
                    createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    essence: nil
                ),
                totalDays: 2,
                purposeLabel: "Focus",
                windLevel: .low,
                isBlownAway: false,
                todayUsedMinutes: 30,
                dailyLimitMinutes: 120,
                fullStats: .mock(days: 2),
                limitedAppCount: 5,
                canProgress: true
            )
        }
}
#endif

