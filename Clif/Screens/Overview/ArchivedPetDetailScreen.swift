import SwiftUI

struct ArchivedPetDetailScreen: View {
    let pet: ArchivedPet

    @Environment(\.dismiss) private var dismiss
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @State private var showAppUsageSheet = false
    @State private var showBreakHistory = false
    @State private var showDeleteConfirmation = false

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

                    DayByDayUsageCard(
                        stats: pet.fullStats,
                        petId: pet.id,
                        limitMinutes: Int(pet.preset.minutesToBlowAway)
                    )

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

                    deleteButton
                }
                .padding()
            }
            .sheet(isPresented: $showBreakHistory) {
                BreakHistorySheet(breakHistory: pet.breakHistory)
            }
            .sheet(isPresented: $showAppUsageSheet) {
                LimitedAppsSheet(sources: pet.limitedSources)
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
            .sheet(isPresented: $showDeleteConfirmation) {
                DeletePetSheet(
                    petName: pet.name,
                    showArchiveOption: false,
                    onDelete: {
                        archivedPetManager.delete(id: pet.id)
                        dismiss()
                    }
                )
            }
        }
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Smazat peta")
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .glassCard()
    }
}

#Preview("Blown") {
    ArchivedPetDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}

#Preview("Fully Evolved") {
    ArchivedPetDetailScreen(pet: .mock(name: "Breeze", phase: 4, isBlown: false, totalDays: 14))
}
