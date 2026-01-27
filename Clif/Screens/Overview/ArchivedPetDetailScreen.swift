import SwiftUI

struct ArchivedPetDetailScreen: View {
    let pet: ArchivedPet

    @Environment(\.dismiss) private var dismiss
    @State private var showAppUsageSheet = false
    @State private var showBreakHistory = false

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
                        purpose: pet.purpose
                    )

                    EssenceInfoCard(evolutionHistory: pet.evolutionHistory)

                    EvolutionCarousel(
                        pet: pet,
                        windLevel: .none,
                        isBlownAway: pet.isBlown,
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

                    if !pet.breakHistory.isEmpty {
                        BreakSummaryButton(
                            breakHistory: pet.breakHistory,
                            onTap: { showBreakHistory = true }
                        )
                    }

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { showAppUsageSheet = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showBreakHistory) {
                BreakHistorySheet(breakHistory: pet.breakHistory)
            }
            .sheet(isPresented: $showAppUsageSheet) {
                AppUsageDetailSheet(
                    sources: pet.limitedSources,
                    preset: pet.preset,
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
    let preset: WindPreset
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
                        Label("Obtížnost", systemImage: "gauge.with.needle.fill")
                        Spacer()
                        Text(preset.displayName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Čas do blow away", systemImage: "wind")
                        Spacer()
                        Text("\(Int(preset.minutesToBlowAway)) min")
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

#Preview("Blown") {
    ArchivedPetDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}

#Preview("Fully Evolved") {
    ArchivedPetDetailScreen(pet: .mock(name: "Breeze", phase: 4, isBlown: false, totalDays: 14))
}

#Preview("App Usage Sheet") {
    AppUsageDetailSheet(
        sources: LimitedSource.mockList(days: 14),
        preset: .balanced,
        totalDays: 14
    )
}
