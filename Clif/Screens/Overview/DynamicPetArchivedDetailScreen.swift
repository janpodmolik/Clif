import SwiftUI

struct DynamicPetArchivedDetailScreen: View {
    let pet: ArchivedDynamicPet

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

                    EssenceInfoCard(evolutionHistory: pet.evolutionHistory)

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

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { showAppUsageSheet = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showAppUsageSheet) {
                DynamicAppUsageDetailSheet(
                    sources: pet.limitedSources,
                    config: pet.config,
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

// MARK: - Dynamic App Usage Detail Sheet

struct DynamicAppUsageDetailSheet: View {
    let sources: [LimitedSource]
    let config: DynamicModeConfig
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
                        Text(config.displayName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Čas do blow away", systemImage: "wind")
                        Spacer()
                        Text("\(Int(config.minutesToBlowAway)) min")
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
    DynamicPetArchivedDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}

#Preview("Fully Evolved") {
    DynamicPetArchivedDetailScreen(pet: .mock(name: "Breeze", phase: 4, isBlown: false, totalDays: 14))
}

#Preview("Dynamic App Usage Sheet") {
    DynamicAppUsageDetailSheet(
        sources: LimitedSource.mockList(days: 14),
        config: .balanced,
        totalDays: 14
    )
}
