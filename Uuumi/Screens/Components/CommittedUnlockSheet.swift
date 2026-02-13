import SwiftUI
import Combine

/// Reactive committed unlock sheet that transitions UI when the committed break duration elapses.
/// While committed: shows warning with dangerous unlock option (pet loss).
/// After duration elapses (break transitions to free via auto-lock): shows green "safe to unlock" state.
struct CommittedUnlockSheet: View {
    var onUnlockDangerous: () -> Void = {}
    var onUnlockSafe: () -> Void = {}

    @State private var refreshTick = 0
    @Environment(\.dismiss) private var dismiss

    /// Whether the committed break has completed (transitioned to free or ended).
    private var isCompleted: Bool {
        let _ = refreshTick
        return ShieldState.shared.currentBreakType != .committed
    }

    var body: some View {
        ConfirmationSheet(
            navigationTitle: isCompleted ? "Break dokončen" : "Committed Break",
            height: 320
        ) {
            ConfirmationHeader(
                icon: isCompleted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                iconColor: isCompleted ? .green : .orange,
                title: isCompleted
                    ? "Committed break skončil"
                    : "Opravdu chceš skončit dřív?",
                subtitle: isCompleted
                    ? "Můžeš bezpečně odemknout bez ztráty mazlíčka."
                    : "Předčasné ukončení způsobí okamžitou ztrátu tvého peta."
            )
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.4), value: isCompleted)

            if isCompleted {
                ConfirmationAction(
                    icon: "lock.open.fill",
                    title: "Odemknout bezpečně",
                    subtitle: "Break byl úspěšně dokončen",
                    foregroundColor: .green,
                    background: .tinted(.green)
                ) {
                    dismiss()
                    onUnlockSafe()
                }
                .transition(.blurReplace)
            } else {
                ConfirmationAction(
                    icon: "xmark.circle",
                    title: "Ukončit a ztratit peta",
                    subtitle: "Nevratná akce",
                    foregroundColor: .red,
                    background: .tinted(.red)
                ) {
                    dismiss()
                    onUnlockDangerous()
                }
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isCompleted)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            refreshTick += 1
        }
    }
}

#if DEBUG
#Preview("Committed Unlock") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            CommittedUnlockSheet(
                onUnlockDangerous: { print("Dangerous unlock") },
                onUnlockSafe: { print("Safe unlock") }
            )
        }
}
#endif
