import SwiftUI

struct PetDetailHeader: View {
    let petName: String
    let mood: Mood
    let totalDays: Int
    let evolutionPhase: Int
    var purpose: String? = nil
    var createdAt: Date? = nil
    var modeInfo: PetModeInfo? = nil

    private var formattedCreatedAt: String? {
        guard let createdAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
        return formatter.string(from: createdAt)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(petName)
                            .font(.title.weight(.bold))

                        Text(mood.emoji)
                            .font(.title2)
                    }

                    if let purpose, !purpose.isEmpty {
                        Text(purpose)
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

            if let modeInfo {
                PetModeInfoSection(modeInfo: modeInfo)
            }
        }
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
#Preview("With Mode Info - Daily") {
    VStack {
        PetDetailHeader(
            petName: "Fern",
            mood: .happy,
            totalDays: 12,
            evolutionPhase: 2,
            purpose: "Social Media",
            createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
            modeInfo: .daily(.init(
                dailyLimitMinutes: 90,
                limitedSources: LimitedSource.mockList()
            ))
        )
    }
    .padding()
}

#Preview("With Mode Info - Dynamic") {
    VStack {
        PetDetailHeader(
            petName: "Storm",
            mood: .neutral,
            totalDays: 5,
            evolutionPhase: 2,
            purpose: "Gaming",
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            modeInfo: .dynamic(.init(
                config: .intense,
                limitedSources: LimitedSource.mockList()
            ))
        )
    }
    .padding()
}

#Preview("Without Mode Info") {
    VStack {
        PetDetailHeader(
            petName: "Bloom",
            mood: .sad,
            totalDays: 1,
            evolutionPhase: 0,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
    }
    .padding()
}
#endif
