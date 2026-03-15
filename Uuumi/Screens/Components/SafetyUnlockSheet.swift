import SwiftUI
import Combine

/// Reactive safety unlock sheet that transitions UI when wind drops below the configured threshold.
/// Instead of dismissing when safe, shows a green "safe to unlock" state with animation.
struct SafetyUnlockSheet: View {
    var onUnlockDangerous: () -> Void = {}
    var onUnlockSafe: () -> Void = {}

    @State private var refreshTick = 0
    @Environment(\.dismiss) private var dismiss

    private var unlockThreshold: Int {
        SharedDefaults.limitSettings.safetyUnlockThreshold
    }

    private var isSafe: Bool {
        let _ = refreshTick
        return ShieldManager.shared.isSafetyUnlockSafe
    }

    var body: some View {
        ConfirmationSheet(
            navigationTitle: isSafe ? "Safe unlock" : "Unlock Safety Shield?",
            height: 320
        ) {
            ConfirmationHeader(
                icon: isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                iconColor: isSafe ? .green : .orange,
                title: isSafe ? "Wind dropped below \(unlockThreshold) %" : "Wind is above \(unlockThreshold) %",
                subtitle: isSafe
                    ? "You can safely unlock without losing your pet."
                    : "Unlocking now will cause loss of your pet."
            )
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.4), value: isSafe)

            if isSafe {
                ConfirmationAction(
                    icon: "lock.open.fill",
                    title: "Unlock safely",
                    subtitle: "Wind is below \(unlockThreshold) %",
                    foregroundColor: .green,
                    background: .tinted(.green)
                ) {
                    dismiss()
                    onUnlockSafe()
                }
                .transition(.blurReplace)
            } else {
                ConfirmationAction(
                    icon: "lock.trianglebadge.exclamationmark.fill",
                    title: "Unlock and lose pet",
                    subtitle: "Wind is still above \(unlockThreshold) %",
                    foregroundColor: .red,
                    background: .tinted(.red)
                ) {
                    dismiss()
                    onUnlockDangerous()
                }
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isSafe)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            refreshTick += 1
        }
    }
}

#if DEBUG
#Preview("Safety Unlock - Dangerous") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            SafetyUnlockSheet(
                onUnlockDangerous: { print("Dangerous unlock") },
                onUnlockSafe: { print("Safe unlock") }
            )
        }
}
#endif
