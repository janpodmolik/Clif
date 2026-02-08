import SwiftUI

struct CommittedUnlockSheet: View {
    var onUnlockDangerous: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ConfirmationSheet(
            navigationTitle: "Committed Break",
            height: 320
        ) {
            ConfirmationHeader(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Opravdu chceš skončit dřív?",
                subtitle: "Předčasné ukončení způsobí okamžitou ztrátu tvého peta."
            )

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
        }
    }
}

#if DEBUG
#Preview("Committed Unlock") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            CommittedUnlockSheet(
                onUnlockDangerous: { print("Dangerous unlock") }
            )
        }
}
#endif
