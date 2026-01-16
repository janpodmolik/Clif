import SwiftUI

struct ArchivedDailyPetHeaderCard: View {
    let petName: String
    let mood: Mood
    let totalDays: Int
    let evolutionPhase: Int
    let purposeLabel: String?
    let createdAt: Date
    let isBlown: Bool
    let archivedAt: Date

    private var moodEmoji: String {
        switch mood {
        case .happy: return "😌"
        case .neutral: return "😐"
        case .sad: return "😞"
        case .blown: return "😵"
        }
    }

    private var statusText: String {
        isBlown ? "Odfouknut" : "Plně evolvován"
    }

    private var statusIcon: String {
        isBlown ? "wind" : "checkmark.circle.fill"
    }

    private var statusColor: Color {
        isBlown ? .red : .green
    }

    var body: some View {
        VStack(spacing: 0) {
            // Archive status section
            HStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 44, height: 44)
                    .background(statusColor.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.headline)

                    Text(formatDate(archivedAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        statusColor.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Pet header section
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

                    Text("Od \(formatDate(createdAt))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview("Fully Evolved") {
    ArchivedDailyPetHeaderCard(
        petName: "Fern",
        mood: .happy,
        totalDays: 12,
        evolutionPhase: 4,
        purposeLabel: "Social Media",
        createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
        isBlown: false,
        archivedAt: Date()
    )
    .padding()
}

#Preview("Blown") {
    ArchivedDailyPetHeaderCard(
        petName: "Sprout",
        mood: .blown,
        totalDays: 5,
        evolutionPhase: 2,
        purposeLabel: "Gaming",
        createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        isBlown: true,
        archivedAt: Date()
    )
    .padding()
}
#endif
