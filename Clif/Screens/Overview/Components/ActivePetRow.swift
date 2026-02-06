import SwiftUI

struct ActivePetRow: View {
    @Environment(PetManager.self) private var petManager
    var refreshTick: Int = 0
    let onTap: () -> Void

    private var pet: Pet? {
        petManager.currentPet
    }

    var body: some View {
        // refreshTick forces SwiftUI to re-evaluate this view and re-read pet from SharedDefaults
        let _ = refreshTick
        if let pet {
            content(for: pet)
        }
    }

    private func content(for pet: Pet) -> some View {
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
                            Text("\(pet.totalDays) dní")
                        }

                        if !pet.isBlob {
                            Text("🧬 \(pet.currentPhase)/\(pet.evolutionHistory.maxPhase)")
                        }
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
                        windIndicator(for: pet)
                        Spacer()
                        windProgressIndicator(for: pet)
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

    private func windIndicator(for pet: Pet) -> some View {
        let effectiveLevel = WindLevel.from(progress: CGFloat(pet.effectiveWindPoints / 100.0))
        let color: Color = pet.isOnBreak ? .cyan : effectiveLevel.color
        return HStack(spacing: 4) {
            Image(systemName: effectiveLevel.icon)
            Text(effectiveLevel.label)
        }
        .font(.caption)
        .foregroundStyle(color)
    }

    private func windProgressIndicator(for pet: Pet) -> some View {
        let color = windProgressColor(for: pet)
        let wind = pet.effectiveWindPoints
        let progress = max(wind / 100.0, 0)
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(wind))%")
                .font(.caption2)
                .foregroundStyle(color)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(width: 50, height: 4)
        }
    }

    private func windProgressColor(for pet: Pet) -> Color {
        if pet.isOnBreak {
            return .cyan
        }
        let effectiveLevel = WindLevel.from(progress: CGFloat(pet.effectiveWindPoints / 100.0))
        return effectiveLevel.color
    }
}

#Preview("Normal") {
    ActivePetRow {}
        .padding()
        .environment(PetManager.mock())
}

#Preview("Blown Away") {
    ActivePetRow {}
        .padding()
        .environment(PetManager.mock(isBlownAway: true))
}
