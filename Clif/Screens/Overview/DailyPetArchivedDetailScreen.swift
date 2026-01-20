import SwiftUI

struct DailyPetArchivedDetailScreen: View {
    let pet: ArchivedDailyPet

    @Environment(\.dismiss) private var dismiss
    @State private var showAppUsageSheet = false

    private var mood: Mood {
        pet.isBlown ? .blown : .happy
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ArchivedPetHeaderCard(
                        petName: pet.name,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.finalPhase,
                        createdAt: pet.evolutionHistory.createdAt,
                        isBlown: pet.isBlown,
                        archivedAt: pet.archivedAt,
                        purpose: pet.purpose,
                        modeInfo: PetModeInfo(from: pet)
                    )

                    if pet.essence != nil {
                        EssenceInfoCard(evolutionHistory: pet.evolutionHistory)
                    }

                    EvolutionCarousel(
                        pet: pet,
                        mood: mood,
                        showCurrentBadge: false
                    )

                    EvolutionTimelineView(
                        history: pet.evolutionHistory,
                        canEvolve: false,
                        daysUntilEvolution: nil,
                        showPulse: false
                    )

                    UsageCard(stats: pet.fullStats)

                    TrendMiniChart(stats: pet.fullStats)

                    LimitStatsCard(
                        dailyLimitMinutes: pet.dailyLimitMinutes,
                        dailyStats: pet.dailyStats,
                        totalDays: pet.totalDays,
                        themeColor: pet.themeColor
                    )

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { showAppUsageSheet = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showAppUsageSheet) {
                AppUsageDetailSheet(
                    sources: pet.limitedSources,
                    dailyLimitMinutes: pet.dailyLimitMinutes,
                    totalDays: pet.totalDays
                )
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
        }
    }

}

// MARK: - App Usage Detail Sheet

struct AppUsageDetailSheet: View {
    let sources: [LimitedSource]
    let dailyLimitMinutes: Int
    let totalDays: Int

    @Environment(\.dismiss) private var dismiss

    private var totalMinutes: Int {
        sources.reduce(0) { $0 + $1.totalMinutes }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Denní limit", systemImage: "clock.fill")
                        Spacer()
                        Text(formatMinutes(dailyLimitMinutes))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Aktivních dní", systemImage: "calendar")
                        Spacer()
                        Text("\(totalDays)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Celkový čas", systemImage: "hourglass")
                        Spacer()
                        Text(formatMinutes(totalMinutes))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Limitované zdroje") {
                    ForEach(sources) { source in
                        HStack {
                            Text(source.displayName)

                            Spacer()

                            Text(formatMinutes(source.totalMinutes))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Statistiky")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

#Preview {
    DailyPetArchivedDetailScreen(pet: .mock(name: "Fern", phase: 4, isBlown: false))
}

#Preview("Blown Pet") {
    DailyPetArchivedDetailScreen(pet: .mock(name: "Sprout", phase: 2, isBlown: true))
}

#Preview("App Usage Sheet") {
    AppUsageDetailSheet(
        sources: LimitedSource.mockList(days: 14),
        dailyLimitMinutes: 60,
        totalDays: 14
    )
}
