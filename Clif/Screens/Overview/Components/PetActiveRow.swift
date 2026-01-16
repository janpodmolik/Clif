import SwiftUI

struct PetActiveRow: View {
    let pet: ActivePet
    let onTap: () -> Void

    private var mood: Mood {
        Mood(from: pet.windLevel)
    }

    private var progress: Double {
        guard pet.dailyLimitMinutes > 0 else { return 0 }
        return min(Double(pet.todayUsedMinutes) / Double(pet.dailyLimitMinutes), 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(pet.assetName(for: mood))
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
                    windIndicator
                    Spacer()
                    progressIndicator
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var windIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: pet.windLevel.icon)
            Text(pet.windLevel.label)
        }
        .font(.caption)
        .foregroundStyle(pet.windLevel.color)
    }

    private var remainingMinutes: Int {
        max(pet.dailyLimitMinutes - pet.todayUsedMinutes, 0)
    }

    private var progressIndicator: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(remainingMinutes > 0 ? "zbývá \(remainingMinutes)m" : "limit překročen")
                .font(.caption2)
                .foregroundStyle(remainingMinutes > 0 ? Color.secondary : Color.red)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(width: 50, height: 4)
        }
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PetActiveRow(pet: .mock(name: "Fern", phase: 2, todayUsedMinutes: 0)) {}
        PetActiveRow(pet: .mock(name: "Ivy", phase: 3, todayUsedMinutes: 45)) {}
        PetActiveRow(pet: .mock(name: "Sage", phase: 2, todayUsedMinutes: 67)) {}
        PetActiveRow(pet: .mock(name: "Willow", phase: 1, todayUsedMinutes: 130, dailyLimitMinutes: 120)) {}
    }
    .padding()
}
