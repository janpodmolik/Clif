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

    private var relativeDate: String {
        Self.relativeDateFormatter.localizedString(for: pet.archivedAt, relativeTo: Date())
    }

    /// Blown and lost pets use faded visual treatment.
    private var isFaded: Bool {
        pet.archiveReason == .blown || pet.archiveReason == .lost
    }

    private var reasonLabel: (icon: String, text: String, color: Color)? {
        switch pet.archiveReason {
        case .blown: ("wind", "Odfouknut", .red)
        case .lost: ("icloud.slash", "Ztracen", .secondary)
        case .completed, .manual: nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(pet.assetName(for: .none, isBlownAway: pet.isBlown))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .scaleEffect(pet.displayScale)
                    .opacity(isFaded ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundStyle(isFaded ? .secondary : .primary)

                    if let purpose = pet.purpose {
                        Text(purpose)
                            .font(.subheadline)
                            .foregroundStyle(isFaded ? .tertiary : .secondary)
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
                    .foregroundStyle(isFaded ? .tertiary : .secondary)
                }

                Spacer()

                if let reason = reasonLabel {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(relativeDate)
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()
                            .frame(minHeight: 0)

                        HStack(spacing: 4) {
                            Image(systemName: reason.icon)
                            Text(reason.text)
                        }
                        .font(.caption)
                        .foregroundStyle(reason.color)
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
    VStack(spacing: 12) {
        ArchivedPetRow(pet: .mock(name: "Fern", phase: 4, archiveReason: .completed)) {}
        ArchivedPetRow(pet: .mock(name: "Sprout", phase: 2, archiveReason: .blown)) {}
        ArchivedPetRow(pet: .mock(name: "Moss", phase: 3, archiveReason: .manual)) {}
        ArchivedPetRow(pet: .mock(name: "Ghost", phase: 1, archiveReason: .lost)) {}
    }
    .padding()
}
