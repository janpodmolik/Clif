import SwiftUI

struct PetHistoryRow: View {
    let pet: ArchivedPet
    let onTap: () -> Void

    private var assetName: String {
        let mood: Mood = pet.isBlown ? .sad : .happy
        return pet.phase?.assetName(for: mood) ?? pet.essence.assetName
    }

    private var displayScale: CGFloat {
        pet.phase?.displayScale ?? 1.0
    }

    private var statusText: String {
        if pet.isBlown {
            return "Odfouknut"
        } else if pet.isCompleted {
            return "Dokončeno"
        } else {
            return "Archivováno"
        }
    }

    private var statusIcon: String {
        if pet.isBlown {
            return "wind"
        } else if pet.isCompleted {
            return "checkmark.circle.fill"
        } else {
            return "archivebox.fill"
        }
    }

    private var statusColor: Color {
        if pet.isBlown {
            return .red
        } else if pet.isCompleted {
            return .green
        } else {
            return .secondary
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .bottom, spacing: 14) {
                // Pet image
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(displayScale)
                    .opacity(pet.isBlown ? 0.5 : 1.0)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(.headline)

                        Spacer()

                        // Status badge
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                            Text(statusText)
                        }
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    }

                    HStack {
                        if let purpose = pet.purpose {
                            Text(purpose)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("Fáze \(pet.finalPhase)/\(pet.evolutionHistory.maxPhase)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    HStack(spacing: 12) {
                        Label("\(pet.totalDays) dní", systemImage: "calendar")

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(pet.finalStreak)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        PetHistoryRow(pet: .mock(name: "Fern", phase: 4, isBlown: false)) {}
        PetHistoryRow(pet: .mock(name: "Sprout", phase: 2, isBlown: true)) {}
        PetHistoryRow(pet: .mock(name: "Moss", phase: 3, isBlown: false)) {}
    }
    .padding()
}
