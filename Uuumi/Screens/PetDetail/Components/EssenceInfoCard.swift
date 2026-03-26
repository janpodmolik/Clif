import SwiftUI

struct EssenceInfoCard: View {
    let evolutionHistory: EvolutionHistory

    private var firstEvolutionDate: Date? {
        evolutionHistory.events.first?.date
    }

    private var evolutionCount: Int {
        evolutionHistory.events.count
    }

    var body: some View {
        if let essence = evolutionHistory.essence {
            cardContent(
                iconName: essence.assetName,
                name: EvolutionPath.path(for: essence).displayName,
                color: .green
            )
        } else if evolutionHistory.hasUnknownEssence, let essenceId = evolutionHistory.essenceRawValue {
            cardContent(
                iconName: "unknown-essence",
                name: "Essence #\(essenceId)",
                color: .orange
            )
        } else {
            EmptyView()
        }
    }

    private func cardContent(iconName: String, name: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                if evolutionHistory.hasUnknownEssence {
                    Text("Unknown essence")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else if let date = firstEvolutionDate {
                    Text("Since \(formatDate(date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if evolutionCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(evolutionCount)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(color)

                    Text(evolutionCount == 1 ? "evolution" : "evolutions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .glassCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview("With Evolutions") {
    EssenceInfoCard(
        evolutionHistory: EvolutionHistory(
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            essence: .plant,
            events: [
                EvolutionEvent(fromPhase: 1, toPhase: 2, date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!),
                EvolutionEvent(fromPhase: 2, toPhase: 3, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
            ]
        )
    )
    .padding()
}

#Preview("Phase 1 - No evolutions yet") {
    EssenceInfoCard(
        evolutionHistory: EvolutionHistory(
            createdAt: Date(),
            essence: .plant,
            events: []
        )
    )
    .padding()
}
#endif
