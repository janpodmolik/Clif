import SwiftUI

struct ArchivedPetRow: View {
    let pet: ArchivedPetSummary
    let onTap: () -> Void

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.unitsStyle = .short
        return formatter
    }()

    private var mood: Mood {
        pet.isBlown ? .sad : .happy
    }

    private var relativeDate: String {
        Self.relativeDateFormatter.localizedString(for: pet.archivedAt, relativeTo: Date())
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(pet.assetName(for: mood))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(pet.displayScale)
                    .opacity(pet.isBlown ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundStyle(pet.isBlown ? .secondary : .primary)

                    if let purpose = pet.purpose {
                        Text(purpose)
                            .font(.subheadline)
                            .foregroundStyle(pet.isBlown ? .tertiary : .secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("\(pet.totalDays) dní")
                        }

                        if pet.finalPhase < pet.evolutionHistory.maxPhase {
                            Text("🧬 \(pet.finalPhase)/\(pet.evolutionHistory.maxPhase)")
                        } else {
                            Text("🧬 \(pet.evolutionHistory.maxPhase)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(pet.isBlown ? .tertiary : .secondary)
                }

                Spacer()

                if pet.isBlown {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(relativeDate)
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()
                            .frame(minHeight: 0)

                        HStack(spacing: 4) {
                            Image(systemName: "wind")
                            Text("Odfouknut")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                } else {
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background {
                if pet.isBlown {
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
    VStack(spacing: 12) {
        ArchivedPetRow(pet: .mock(name: "Fern", phase: 4, isBlown: false)) {}
        ArchivedPetRow(pet: .mock(name: "Sprout", phase: 2, isBlown: true)) {}
        ArchivedPetRow(pet: .mock(name: "Moss", phase: 3, isBlown: false)) {}
    }
    .padding()
}
