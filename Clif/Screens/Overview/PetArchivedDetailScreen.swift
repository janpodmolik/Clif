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
                    ArchiveStatusCard(
                        isBlown: pet.isBlown,
                        archivedAt: pet.archivedAt
                    )

                    PetDetailHeader(
                        petName: pet.name,
                        mood: mood,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.finalPhase,
                        purposeLabel: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt
                    )

                    if pet.essence != nil {
                        EssenceInfoCard(evolutionHistory: pet.evolutionHistory)
                    }

                    EvolutionCarousel(
                        pet: pet,
                        mood: mood
                    )

                    EvolutionTimelineView(
                        history: pet.evolutionHistory,
                        blownAt: pet.evolutionHistory.blownAt,
                        canEvolve: false,
                        daysUntilEvolution: nil
                    )

                    UsageCard(stats: pet.fullStats)

                    TrendMiniChart(stats: pet.fullStats)

                    limitStatsCard

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

    // MARK: - Limit Stats Card

    private var totalMinutesUsed: Int {
        pet.dailyStats.reduce(0) { $0 + $1.totalMinutes }
    }

    private var totalLimitMinutes: Int {
        pet.dailyLimitMinutes * pet.totalDays
    }

    private var averageDailyMinutes: Int {
        guard pet.totalDays > 0 else { return 0 }
        return totalMinutesUsed / pet.totalDays
    }

    private var usageProgress: Double {
        guard totalLimitMinutes > 0 else { return 0 }
        return min(Double(totalMinutesUsed) / Double(totalLimitMinutes), 1.0)
    }

    private var limitStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tvůj limit")
                .font(.headline)

            HStack(spacing: 12) {
                limitStatItem(
                    title: "Denní limit",
                    value: formatMinutes(pet.dailyLimitMinutes),
                    icon: "clock.fill"
                )

                limitStatItem(
                    title: "Průměr/den",
                    value: formatMinutes(averageDailyMinutes),
                    icon: "chart.bar.fill"
                )

                limitStatItem(
                    title: "Aktivních dní",
                    value: "\(pet.totalDays)",
                    icon: "calendar"
                )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(pet.themeColor)
                        .frame(width: geometry.size.width * usageProgress)
                }
            }
            .frame(height: 8)

            Text("Celkem jsi využil **\(formatMinutes(totalMinutesUsed))** z \(formatMinutes(totalLimitMinutes))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func limitStatItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(pet.themeColor)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
