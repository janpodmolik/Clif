import SwiftUI

struct DynamicPetArchivedDetailScreen: View {
    let pet: ArchivedDynamicPet

    @Environment(\.dismiss) private var dismiss

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
                        purposeLabel: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt,
                        isBlown: pet.isBlown,
                        archivedAt: pet.archivedAt
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
                        sources: pet.limitedSources
                    )
                }
                .padding()
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

#Preview("Blown") {
    DynamicPetArchivedDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}

#Preview("Fully Evolved") {
    DynamicPetArchivedDetailScreen(pet: .mock(name: "Breeze", phase: 4, isBlown: false, totalDays: 14))
}
