import SwiftUI

/// Shared unlock confirmation sheets for safety and committed break types.
/// Attach via `.unlockConfirmations(...)` to any view that needs unlock flow.
struct UnlockConfirmations: ViewModifier {
    @Binding var showCommittedConfirmation: Bool
    @Binding var showSafetyConfirmation: Bool

    @Environment(PetManager.self) private var petManager

    private var shieldState: ShieldState { .shared }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showCommittedConfirmation) {
                CommittedUnlockSheet(
                    onUnlockDangerous: {
                        ShieldManager.shared.toggle(success: false)
                        petManager.blowAwayCurrentPet(reason: .breakViolation)
                    },
                    onUnlockSafe: {
                        ShieldManager.shared.toggle()
                    }
                )
            }
            .sheet(isPresented: $showSafetyConfirmation) {
                SafetyUnlockSheet(
                    onUnlockDangerous: {
                        let result = ShieldManager.shared.processSafetyShieldUnlock()
                        if result == .blownAway {
                            petManager.blowAwayCurrentPet(reason: .limitExceeded)
                        }
                    },
                    onUnlockSafe: {
                        ShieldManager.shared.processSafetyShieldUnlock()
                    }
                )
            }
            .onChange(of: shieldState.isActive) { _, isActive in
                if !isActive {
                    showCommittedConfirmation = false
                    showSafetyConfirmation = false
                }
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
