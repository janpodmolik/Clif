import SwiftUI

struct PetDetailHeader: View {
    let petName: String
    let mood: Mood
    let streak: Int
    let purposeLabel: String?

    private var moodEmoji: String {
        switch mood {
        case .happy: return "😌"
        case .neutral: return "😐"
        case .sad: return "😞"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
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

            streakBadge
        }
        .padding()
        .glassCard()
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)

            Text("\(streak)")
                .fontWeight(.semibold)

            Text("days")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.15), in: Capsule())
    }
}

#if DEBUG
#Preview {
    VStack {
        PetDetailHeader(
            petName: "Fern",
            mood: .happy,
            streak: 12,
            purposeLabel: "Social Media"
        )

        PetDetailHeader(
            petName: "Bloom",
            mood: .sad,
            streak: 3,
            purposeLabel: nil
        )
    }
    .padding()
}
#endif
