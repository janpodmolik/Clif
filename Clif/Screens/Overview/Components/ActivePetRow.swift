import SwiftUI

struct ActivePetRow: View {
    let pet: Pet
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(pet.assetName(for: pet.windLevel))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(pet.displayScale)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.headline)

                    if let purpose = pet.purpose {
                        Text(purpose)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.green)
                            Text("\(pet.totalDays) dní")
                        }

                        Text("🧬 \(pet.currentPhase)/\(pet.evolutionHistory.maxPhase)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if pet.isBlown {
                        blownAwayBadge
                        Spacer()
                    } else {
                        windIndicator
                        Spacer()
                        windProgressIndicator
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var blownAwayBadge: some View {
        Text("Blown Away")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.15))
            .foregroundStyle(.red)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var windIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: pet.windLevel.icon)
            Text(pet.windLevel.label)
        }
        .font(.caption)
        .foregroundStyle(pet.windLevel.color)
    }

    private var windProgressIndicator: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(pet.windPoints))%")
                .font(.caption2)
                .foregroundStyle(windProgressColor)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(windProgressColor)
                        .frame(width: geometry.size.width * pet.windProgress)
                }
            }
            .frame(width: 50, height: 4)
        }
    }

    private var windProgressColor: Color {
        if pet.windProgress >= 0.8 {
            return .red
        } else if pet.windProgress >= 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview("Normal") {
    ActivePetRow(pet: .mock(name: "Fern", phase: 2, windPoints: 45)) {}
        .padding()
}

#Preview("Blown Away") {
    ActivePetRow(pet: .mock(name: "Blown", phase: 2, windPoints: 100, isBlownAway: true)) {}
        .padding()
}
