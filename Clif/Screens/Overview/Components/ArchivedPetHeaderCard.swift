import SwiftUI

struct ArchivedPetHeaderCard: View {
    let petName: String
    let totalDays: Int
    let evolutionPhase: Int
    let createdAt: Date
    let archiveReason: ArchiveReason
    let archivedAt: Date
    var purpose: String? = nil

    private var statusText: String {
        switch archiveReason {
        case .blown: "Odfouknut"
        case .completed: "Plně evolvován"
        case .lost: "Ztracen"
        case .manual: "Archivován"
        }
    }

    private var statusIcon: String {
        switch archiveReason {
        case .blown: "wind"
        case .completed: "checkmark.circle.fill"
        case .lost: "icloud.slash"
        case .manual: "archivebox"
        }
    }

    private var statusColor: Color {
        switch archiveReason {
        case .blown: .red
        case .completed: .green
        case .lost: .secondary
        case .manual: .orange
        }
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
                    Text(petName)
                        .font(.title.weight(.bold))

                    if let purpose, !purpose.isEmpty {
                        Text(purpose)
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
    ArchivedPetHeaderCard(
        petName: "Fern",
        totalDays: 12,
        evolutionPhase: 4,
        createdAt: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
        archiveReason: .completed,
        archivedAt: Date(),
        purpose: "Social Media"
    )
    .padding()
}

#Preview("Blown") {
    ArchivedPetHeaderCard(
        petName: "Storm",
        totalDays: 5,
        evolutionPhase: 2,
        createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        archiveReason: .blown,
        archivedAt: Date(),
        purpose: "Gaming"
    )
    .padding()
}

#Preview("Lost") {
    ArchivedPetHeaderCard(
        petName: "Sprout",
        totalDays: 3,
        evolutionPhase: 1,
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        archiveReason: .lost,
        archivedAt: Date()
    )
    .padding()
}

#Preview("Manual") {
    ArchivedPetHeaderCard(
        petName: "Moss",
        totalDays: 7,
        evolutionPhase: 2,
        createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        archiveReason: .manual,
        archivedAt: Date(),
        purpose: "Gaming"
    )
    .padding()
}
#endif
