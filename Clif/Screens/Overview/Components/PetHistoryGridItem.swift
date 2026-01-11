import SwiftUI

struct PetHistoryGridItem: View {
    let pet: ArchivedPet
    let onTap: () -> Void

    private var assetName: String {
        let mood: Mood = pet.isBlown ? .sad : .happy
        return pet.phase?.assetName(for: mood) ?? pet.essence.assetName
    }

    private var displayScale: CGFloat {
        pet.phase?.displayScale ?? 1.0
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.M."
        return formatter.string(from: pet.archivedAt)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text(pet.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(pet.isBlown ? .secondary : .primary)

                    if let purpose = pet.purpose {
                        Text(purpose)
                            .font(.caption)
                            .foregroundStyle(pet.isBlown ? .tertiary : .secondary)
                            .lineLimit(1)
                    }
                }

                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .scaleEffect(displayScale)
                    .opacity(pet.isBlown ? 0.5 : 1.0)
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(pet.totalDays)")
                    }

                    if pet.finalPhase < pet.evolutionHistory.maxPhase {
                        Text("🧬\(pet.finalPhase)/\(pet.evolutionHistory.maxPhase)")
                    } else {
                        Text("🧬\(pet.evolutionHistory.maxPhase)")
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                        Text(shortDate)
                    }
                }
                .font(.caption2)
                .foregroundStyle(pet.isBlown ? .tertiary : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background {
                if pet.isBlown {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(pet.essence.themeColor.opacity(0.15))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        PetHistoryGridItem(pet: .mock(name: "Fern", phase: 4, isBlown: false)) {}
        PetHistoryGridItem(pet: .mock(name: "Sprout", phase: 2, isBlown: true)) {}
        PetHistoryGridItem(pet: .mock(name: "Moss", phase: 3, isBlown: false)) {}
        PetHistoryGridItem(pet: .mock(name: "Willow", phase: 1, isBlown: false)) {}
    }
    .padding()
}
