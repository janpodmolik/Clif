import SwiftUI

struct ArchivedPetGridItem: View {
    let pet: ArchivedPetSummary
    let onTap: () -> Void

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.M."
        return formatter.string(from: pet.archivedAt)
    }

    /// Blown pets use faded visual treatment.
    private var isFaded: Bool {
        pet.archiveReason == .blown
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text(pet.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFaded ? .secondary : .primary)

                    if let purpose = pet.purpose {
                        Text(purpose)
                            .font(.caption)
                            .foregroundStyle(isFaded ? .tertiary : .secondary)
                            .lineLimit(1)
                    }
                }

                Image(pet.assetName(for: .none, isBlownAway: pet.isBlown))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .scaleEffect(pet.displayScale)
                    .opacity(isFaded ? 0.5 : 1.0)
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
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
                .foregroundStyle(isFaded ? .tertiary : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background {
                if isFaded {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(pet.themeColor.opacity(0.15))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ArchivedPetGridItem(pet: .mock(name: "Fern", phase: 4, archiveReason: .completed)) {}
        ArchivedPetGridItem(pet: .mock(name: "Sprout", phase: 2, archiveReason: .blown)) {}
        ArchivedPetGridItem(pet: .mock(name: "Moss", phase: 3, archiveReason: .manual)) {}
    }
    .padding()
}
