import FamilyControls
import SwiftUI

/// Sheet shown when a reinstall is detected: Keychain token survived but onboarding was wiped.
/// Multi-phase flow:
/// 1. Decision   — what to do with the cloud pet (continue / archive / delete)
/// 2. Reauthorize — request FamilyControls authorization
/// 3. Picker     — select monitored apps
struct WelcomeBackSheet: View {
    let cloudPet: ActivePetDTO
    /// Called when user finishes. `appSelection` is non-nil only for `.continueWithPet`.
    let onResolve: (SyncManager.WelcomeBackAction, Bool, FamilyActivitySelection?) -> Void

    @State private var phase: Phase = .decision
    @State private var isResolving = false
    @State private var showReOnboardingPrompt = false
    @State private var pendingAction: SyncManager.WelcomeBackAction?
    @State private var appSelection = FamilyActivitySelection()

    enum Phase { case decision, reauthorize, picker }

    var body: some View {
        NavigationStack {
            switch phase {
            case .decision:
                WelcomeBackDecisionPhase(
                    cloudPet: cloudPet,
                    isResolving: isResolving,
                    onContinue: { withAnimation { phase = .reauthorize } },
                    onArchive: { pendingAction = .archivePet; showReOnboardingPrompt = true },
                    onDelete: { pendingAction = .deletePet; showReOnboardingPrompt = true }
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
                    onConfirm: { resolve(.continueWithPet, selection: appSelection) },
                    onBack: { withAnimation { phase = .reauthorize } }
                )
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            dialogTitle,
            isPresented: $showReOnboardingPrompt,
            titleVisibility: .visible
        ) {
            Button("Projít onboarding") {
                if let action = pendingAction { resolve(action, runOnboarding: true) }
            }
            Button("Jít na domovskou") {
                if let action = pendingAction { resolve(action, runOnboarding: false) }
            }
            Button("Zpět", role: .cancel) { pendingAction = nil }
        } message: {
            Text("Co chceš dělat dál?")
        }
    }

    private var dialogTitle: String {
        switch pendingAction {
        case .archivePet: "\(cloudPet.name) bude archivován"
        case .deletePet:  "\(cloudPet.name) bude smazán"
        default:          "Co chceš dělat dál?"
        }
    }

    private func resolve(
        _ action: SyncManager.WelcomeBackAction,
        runOnboarding: Bool = false,
        selection: FamilyActivitySelection? = nil
    ) {
        isResolving = true
        onResolve(action, runOnboarding, selection)
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
    WelcomeBackSheet(cloudPet: cloudDTO) { _, _, _ in }
}
#endif
