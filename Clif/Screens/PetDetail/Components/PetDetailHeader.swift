import SwiftUI

struct PetDetailHeader: View {
    let petName: String
    let mood: Mood
    let totalDays: Int
    let evolutionPhase: Int
    let purposeLabel: String?

    private var moodEmoji: String {
        switch mood {
        case .happy: return "😌"
        case .neutral: return "😐"
        case .sad: return "😞"
        case .blown: return "😵"
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(petName)
                        .font(.title.weight(.bold))

                    Text(moodEmoji)
                        .font(.title2)
                }

                if let purposeLabel, !purposeLabel.isEmpty {
                    Text(purposeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            purposeLabel: "Social Media"
        )

        PetDetailHeader(
            petName: "Bloom",
            mood: .sad,
            totalDays: 3,
            evolutionPhase: 4,
            purposeLabel: nil
        )
    }
    .padding()
}
#endif
