import SwiftUI

struct WelcomeBackDecisionPhase: View {
    let cloudPet: ActivePetDTO
    let isResolving: Bool
    let onContinue: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    @State private var showArchiveConfirm = false
    @State private var showDeleteConfirm = false

    private var cloudEvolutionHistory: EvolutionHistory {
        EvolutionHistory(from: cloudPet.evolutionHistory)
    }
    private var cloudEssence: Essence? { cloudEvolutionHistory.essence }
    private var cloudPhase: Int { cloudEvolutionHistory.currentPhase }
    private var cloudDaysAlive: Int {
        let calendar = Calendar.current
        let created = calendar.startOfDay(for: cloudEvolutionHistory.createdAt)
        let today = calendar.startOfDay(for: Date())
        return (calendar.dateComponents([.day], from: created, to: today).day ?? 0) + 1
    }
    private var canArchive: Bool { cloudDaysAlive > PetManager.minimumArchiveDays }

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                Text("Welcome back!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Your pet was waiting for you in the cloud. What would you like to do?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            petCard

            VStack(spacing: 12) {
                WelcomeBackActionButton(
                    icon: "arrow.right.circle.fill",
                    title: "Continue with \(cloudPet.name)",
                    subtitle: "Pet will be restored from cloud",
                    iconColor: nil,
                    action: onContinue
                )

                if canArchive {
                    WelcomeBackActionButton(
                        icon: "archivebox.fill",
                        title: "Archive \(cloudPet.name)",
                        subtitle: "Pet goes to archive, start fresh",
                        iconColor: .orange,
                        action: { showArchiveConfirm = true }
                    )
                }

                WelcomeBackActionButton(
                    icon: "trash.fill",
                    title: "Delete \(cloudPet.name)",
                    subtitle: "Pet will be permanently deleted",
                    iconColor: .red,
                    action: { showDeleteConfirm = true }
                )
            }

            Spacer()
        }
        .padding(24)
        .disabled(isResolving)
        .overlay {
            if isResolving { ProgressView().scaleEffect(1.5) }
        }
        .confirmationDialog(
            "\(cloudPet.name) will be archived",
            isPresented: $showArchiveConfirm,
            titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive, action: onArchive)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pet will go to the archive and you will continue with onboarding.")
        }
        .confirmationDialog(
            "\(cloudPet.name) will be deleted",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pet will be permanently deleted and you will continue with onboarding.")
        }
    }

    private var petCard: some View {
        HStack(spacing: 16) {
            petImage
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(cloudPet.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    if cloudPhase > 0 {
                        Label("Phase \(cloudPhase)", systemImage: "sparkles")
                    } else {
                        Label("Blob", systemImage: "circle.fill")
                    }
                    Label("\(cloudDaysAlive) days", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var petImage: some View {
        if let essence = cloudEssence,
           let phaseData = EvolutionPath.path(for: essence).phase(at: cloudPhase) {
            PetImage(phaseData, isBlownAway: cloudPet.isBlownAway)
        } else if cloudEssence == nil {
            PetImage(Blob.shared, isBlownAway: cloudPet.isBlownAway)
        } else {
            Image(systemName: "questionmark.circle")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WelcomeBackDecisionPhase(
            cloudPet: ActivePetDTO(
                from: PetLocalDTO(from: Pet.mock(name: "Kořen", phase: 2, essence: .plant, totalDays: 7)),
                userId: UUID(), windPoints: 20, isBlownAway: false, hourlyPerDay: []
            ),
            isResolving: false,
            onContinue: {}, onArchive: {}, onDelete: {}
        )
    }
}
#endif
