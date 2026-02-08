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
        guard let essence = evolutionHistory.essence else { return AnyView(EmptyView()) }
        return AnyView(cardContent(essence: essence))
    }

    private func cardContent(essence: Essence) -> some View {
        let color = EvolutionPath.path(for: essence).themeColor
        let name = EvolutionPath.path(for: essence).displayName

        return HStack(spacing: 16) {
            Image(essence.assetName)
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                if let date = firstEvolutionDate {
                    Text("Od \(formatDate(date))")
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

                    Text(evolutionCount == 1 ? "evoluce" : "evolucí")
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
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
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
