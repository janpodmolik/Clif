import SwiftUI

struct ArchivedPetDetailScreen: View {
    let pet: ArchivedPet

    @Environment(\.dismiss) private var dismiss

    private var mood: Mood {
        pet.isBlown ? .blown : .happy
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusBadge

                    PetDetailHeader(
                        petName: pet.name,
                        mood: mood,
                        streak: pet.totalDays,
                        evolutionPhase: pet.finalPhase,
                        purposeLabel: pet.purpose
                    )

                    EvolutionCarousel(
                        currentPhase: pet.finalPhase,
                        essence: pet.essence,
                        mood: mood,
                        isBlownAway: pet.isBlown,
                        themeColor: pet.essence.themeColor
                    )

                    EvolutionTimelineView(
                        history: pet.evolutionHistory,
                        blownAt: pet.evolutionHistory.blownAt,
                        canEvolve: false,
                        daysUntilEvolution: nil
                    )

                    summaryCard
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

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: pet.isBlown ? "wind" : "trophy.fill")
                .foregroundStyle(pet.isBlown ? .red : .yellow)

            Text(pet.isBlown ? "Odfouknut" : "Dokončeno")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shrnutí")
                .font(.headline)

            HStack {
                summaryItem(
                    icon: "flame.fill",
                    title: "Celkem dní",
                    value: "\(pet.totalDays)",
                    iconColor: .orange
                )

                Spacer()

                summaryItem(
                    icon: "sparkles",
                    title: "Fáze",
                    value: "\(pet.finalPhase)/\(pet.evolutionHistory.maxPhase)"
                )
            }

            if let date = formatDate(pet.archivedAt) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(pet.isBlown ? "Odfouknut \(date)" : "Dokončeno \(date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .glassCard()
    }

    private func summaryItem(
        icon: String,
        title: String,
        value: String,
        iconColor: Color = .secondary
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
        return formatter.string(from: date)
    }
}

#Preview {
    ArchivedPetDetailScreen(pet: .mock(name: "Fern", phase: 4, isBlown: false))
}

#Preview("Blown Pet") {
    ArchivedPetDetailScreen(pet: .mock(name: "Sprout", phase: 2, isBlown: true))
}
