import SwiftUI

/// Shared unlock confirmation dialogs for safety and committed break types.
/// Attach via `.unlockConfirmations(...)` to any view that needs unlock flow.
struct UnlockConfirmations: ViewModifier {
    @Binding var showCommittedConfirmation: Bool
    @Binding var showSafetyConfirmation: Bool

    @Environment(PetManager.self) private var petManager

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Ukončit Committed Break?",
                isPresented: $showCommittedConfirmation,
                titleVisibility: .visible
            ) {
                Button("Ukončit a ztratit peta", role: .destructive) {
                    ShieldManager.shared.toggle(success: false)
                    petManager.blowAwayCurrentPet(reason: .breakViolation)
                }
                Button("Pokračovat v pauze", role: .cancel) {}
            } message: {
                Text("Ukončení committed breaku předčasně způsobí okamžitou ztrátu tvého peta. Tato akce je nevratná.")
            }
            .confirmationDialog(
                "Odemknout Safety Shield?",
                isPresented: $showSafetyConfirmation,
                titleVisibility: .visible
            ) {
                Button("Odemknout a ztratit peta", role: .destructive) {
                    let result = ShieldManager.shared.processSafetyShieldUnlock()
                    if result == .blownAway {
                        petManager.blowAwayCurrentPet(reason: .limitExceeded)
                    }
                }
                Button("Počkat, až vítr klesne", role: .cancel) {}
            } message: {
                Text("Vítr je stále nad 80%. Odemčení teď způsobí ztrátu tvého mazlíčka.")
            }
    }
}

extension View {
    func unlockConfirmations(
        showCommitted: Binding<Bool>,
        showSafety: Binding<Bool>
    ) -> some View {
        modifier(UnlockConfirmations(
            showCommittedConfirmation: showCommitted,
            showSafetyConfirmation: showSafety
        ))
    }
}

// MARK: - Shared Unlock Logic

/// Handles unlock action based on current break type.
/// Sets appropriate confirmation binding or unlocks immediately for free breaks.
func handleShieldUnlock(
    shieldState: ShieldState,
    showCommittedConfirmation: Binding<Bool>,
    showSafetyConfirmation: Binding<Bool>
) {
    switch shieldState.currentBreakType {
    case .safety:
        if ShieldManager.shared.isSafetyUnlockSafe {
            ShieldManager.shared.processSafetyShieldUnlock()
        } else {
            showSafetyConfirmation.wrappedValue = true
        }
    case .committed:
        showCommittedConfirmation.wrappedValue = true
    default:
        ShieldManager.shared.toggle()
    }
}
