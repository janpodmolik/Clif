import FamilyControls
import SwiftUI

/// Sheet shown when a reinstall is detected: Keychain token survived but onboarding was wiped.
/// Multi-phase flow:
/// - continueWithPet: decision → reauthorize → picker → notifications → done (skip onboarding)
/// - archivePet / deletePet: decision → done (run onboarding)
struct WelcomeBackSheet: View {
    let cloudPet: ActivePetDTO
    /// Called when user finishes. `appSelection` is non-nil only for `.continueWithPet`.
    let onResolve: (SyncManager.WelcomeBackAction, FamilyActivitySelection?) -> Void

    @State private var phase: Phase = .decision
    @State private var isResolving = false
    @State private var appSelection = FamilyActivitySelection()

    enum Phase { case decision, reauthorize, picker, notifications }

    var body: some View {
        NavigationStack {
            switch phase {
            case .decision:
                WelcomeBackDecisionPhase(
                    cloudPet: cloudPet,
                    isResolving: isResolving,
                    onContinue: { withAnimation { phase = .reauthorize } },
                    onArchive: { resolve(.archivePet) },
                    onDelete: { resolve(.deletePet) }
                )
            case .reauthorize:
                WelcomeBackReauthorizePhase(
                    petName: cloudPet.name,
                    onAuthorized: { withAnimation { phase = .picker } },
                    onBack: { withAnimation { phase = .decision } }
                )
            case .picker:
                WelcomeBackPickerPhase(
                    appSelection: $appSelection,
                    onConfirm: { withAnimation { phase = .notifications } },
                    onBack: { withAnimation { phase = .reauthorize } }
                )
            case .notifications:
                WelcomeBackNotificationPhase(
                    onDone: { resolve(.continueWithPet, selection: appSelection) }
                )
            }
        }
        .interactiveDismissDisabled()
    }

    private func resolve(
        _ action: SyncManager.WelcomeBackAction,
        selection: FamilyActivitySelection? = nil
    ) {
        isResolving = true
        onResolve(action, selection)
    }
}

#if DEBUG
#Preview("Welcome Back") {
    let cloudDTO = ActivePetDTO(
        from: PetLocalDTO(from: Pet.mock(name: "Kořen", phase: 2, essence: .plant, totalDays: 7)),
        userId: UUID(),
        windPoints: 20,
        isBlownAway: false,
        hourlyAggregate: nil,
        hourlyPerDay: []
    )
    WelcomeBackSheet(cloudPet: cloudDTO) { _, _ in }
}
#endif
