import SwiftUI

/// Sheet shown when signing in to an account that has a cloud pet
/// while the device already has a local pet. Non-dismissable.
///
/// User picks which pet to keep; the other is automatically deleted.
struct PetConflictSheet: View {
    let conflict: PetConflictData
    let onResolve: (SyncManager.ConflictResolution) -> Void

    @State private var isResolving = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            ConfirmationHeader(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .orange,
                title: "Dva petové nalezeni",
                subtitle: "Na tomto zařízení je pet a v cloudu je také pet. Vyber, kterého chceš ponechat."
            )

            petCard(
                label: "Na tomto zařízení",
                name: conflict.localPetName,
                phase: conflict.localPetPhase,
                essence: conflict.localPetEssence,
                daysAlive: conflict.localPetDaysAlive,
                isBlown: conflict.localPetIsBlown
            ) {
                resolve(.keepLocal)
            }

            petCard(
                label: "V cloudu",
                name: conflict.cloudPetName,
                phase: conflict.cloudPetPhase,
                essence: conflict.cloudPetEssence,
                daysAlive: conflict.cloudPetDaysAlive,
                isBlown: conflict.cloudPetIsBlown
            ) {
                resolve(.keepCloud)
            }

            Spacer()
        }
        .padding(24)
        .disabled(isResolving)
        .overlay {
            if isResolving {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Components

    @ViewBuilder
    private func petCard(
        label: String,
        name: String,
        phase: Int,
        essence: Essence?,
        daysAlive: Int,
        isBlown: Bool,
        onKeep: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                petImage(essence: essence, phase: phase, isBlown: isBlown)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.headline)

                        if isBlown {
                            Label("Odfouknut", systemImage: "wind")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    HStack(spacing: 12) {
                        if phase > 0 {
                            Label("Fáze \(phase)", systemImage: "sparkles")
                        } else {
                            Label("Blob", systemImage: "circle.fill")
                        }

                        Label("\(daysAlive) dní", systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button("Ponechat \(name)", action: onKeep)
                .buttonStyle(.primary)
        }
    }

    @ViewBuilder
    private func petImage(essence: Essence?, phase: Int, isBlown: Bool) -> some View {
        if let essence {
            let path = EvolutionPath.path(for: essence)
            if let phaseData = path.phase(at: phase) {
                Image(phaseData.assetName(for: .none, isBlownAway: isBlown))
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(Blob.shared.assetName(for: .none, isBlownAway: isBlown))
                .resizable()
                .scaledToFit()
        }
    }

    // MARK: - Actions

    private func resolve(_ resolution: SyncManager.ConflictResolution) {
        isResolving = true
        onResolve(resolution)
    }
}

#if DEBUG
#Preview("Conflict") {
    PetConflictSheet(
        conflict: PetConflictData.preview
    ) { _ in }
}
#endif
