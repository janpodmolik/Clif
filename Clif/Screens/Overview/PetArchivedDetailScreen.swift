import SwiftUI

struct PetArchivedDetailScreen: View {
    let pet: ArchivedPet

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
                        mood: mood,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.finalPhase,
                        purposeLabel: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt,
                        isBlown: pet.isBlown,
                        archivedAt: pet.archivedAt
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

                    LimitedAppsBadge(appCount: pet.appUsage.count) {
                        showAppUsageSheet = true
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showAppUsageSheet) {
                AppUsageDetailSheet(
                    appUsage: pet.appUsage,
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
    let appUsage: [AppUsage]
    let dailyLimitMinutes: Int
    let totalDays: Int

    @Environment(\.dismiss) private var dismiss

    private var totalMinutes: Int {
        appUsage.reduce(0) { $0 + $1.totalMinutes }
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

                Section("Limitované aplikace") {
                    ForEach(appUsage) { app in
                        HStack {
                            Text(app.displayName)

                            Spacer()

                            Text(formatMinutes(app.totalMinutes))
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
    PetArchivedDetailScreen(pet: .mock(name: "Fern", phase: 4, isBlown: false))
}

#Preview("Blown Pet") {
    PetArchivedDetailScreen(pet: .mock(name: "Sprout", phase: 2, isBlown: true))
}

#Preview("App Usage Sheet") {
    AppUsageDetailSheet(
        appUsage: AppUsage.mockList(days: 14),
        dailyLimitMinutes: 60,
        totalDays: 14
    )
}
