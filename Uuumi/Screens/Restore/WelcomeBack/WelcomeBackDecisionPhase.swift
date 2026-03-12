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
                Text("Vítej zpět!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Tvůj pet na tebe čekal v cloudu. Co chceš udělat?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            petCard

            VStack(spacing: 12) {
                WelcomeBackActionButton(
                    icon: "arrow.right.circle.fill",
                    title: "Pokračovat s \(cloudPet.name)",
                    subtitle: "Pet se obnoví ze cloudu",
                    iconColor: nil,
                    action: onContinue
                )

                if canArchive {
                    WelcomeBackActionButton(
                        icon: "archivebox.fill",
                        title: "Archivovat \(cloudPet.name)",
                        subtitle: "Pet jde do archívu, začni znovu",
                        iconColor: .orange,
                        action: { showArchiveConfirm = true }
                    )
                }

                WelcomeBackActionButton(
                    icon: "trash.fill",
                    title: "Smazat \(cloudPet.name)",
                    subtitle: "Pet bude trvale odstraněn",
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
            "\(cloudPet.name) bude archivován",
            isPresented: $showArchiveConfirm,
            titleVisibility: .visible
        ) {
            Button("Archivovat", role: .destructive, action: onArchive)
            Button("Zpět", role: .cancel) {}
        } message: {
            Text("Pet půjde do archívu a ty budeš pokračovat v onboardingu.")
        }
        .confirmationDialog(
            "\(cloudPet.name) bude smazán",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Smazat", role: .destructive, action: onDelete)
            Button("Zpět", role: .cancel) {}
        } message: {
            Text("Pet bude trvale odstraněn a ty budeš pokračovat v onboardingu.")
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
                        Label("Fáze \(cloudPhase)", systemImage: "sparkles")
                    } else {
                        Label("Blob", systemImage: "circle.fill")
                    }
                    Label("\(cloudDaysAlive) dní", systemImage: "calendar")
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
                userId: UUID(), windPoints: 20, isBlownAway: false, hourlyAggregate: nil, hourlyPerDay: []
            ),
            isResolving: false,
            onContinue: {}, onArchive: {}, onDelete: {}
        )
    }
}
#endif
