import SwiftUI

struct PetDetailHeader: View {
    let petName: String
    let mood: Mood
    let totalDays: Int
    let evolutionPhase: Int
    let purposeLabel: String?
    var createdAt: Date? = nil

    private var formattedCreatedAt: String? {
        guard let createdAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
        return formatter.string(from: createdAt)
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(petName)
                        .font(.title.weight(.bold))

                    Text(mood.emoji)
                        .font(.title2)
                }

                if let purposeLabel, !purposeLabel.isEmpty {
                    Text(purposeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let formattedCreatedAt {
                    Text("Od \(formattedCreatedAt)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                if evolutionPhase > 0 {
                    evolutionBadge
                }
                daysBadge
            }
        }
        .padding()
        .glassCard()
    }

    private var evolutionBadge: some View {
        HStack(spacing: 6) {
            Text("🧬")

            Text("\(evolutionPhase)")
                .fontWeight(.semibold)

            Text("evolutions")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.15), in: Capsule())
    }

    private var daysBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)

            Text("\(totalDays)")
                .fontWeight(.semibold)

            Text("days")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.15), in: Capsule())
    }
}

#if DEBUG
#Preview {
    VStack {
        PetDetailHeader(
            petName: "Fern",
            mood: .happy,
            totalDays: 12,
            evolutionPhase: 2,
            purposeLabel: "Social Media",
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date())
        )

        PetDetailHeader(
            petName: "Bloom",
            mood: .sad,
            totalDays: 1,
            evolutionPhase: 0,
            purposeLabel: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
    }
    .padding()
}
#endif
