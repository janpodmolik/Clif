import SwiftUI

/// Confirmation sheet for ending a committed break early (causes pet loss).
struct CommittedUnlockSheet: View {
    var onUnlock: () -> Void = {}

    var body: some View {
        ConfirmationSheet(
            navigationTitle: "Ukončit Committed Break?",
            header: ConfirmationSheetHeader(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Ukončit committed break?",
                subtitle: "Ukončení committed breaku předčasně způsobí okamžitou ztrátu tvého peta. Tato akce je nevratná."
            ),
            actions: [
                ConfirmationSheetAction(
                    icon: "xmark.circle",
                    title: "Ukončit a ztratit peta",
                    subtitle: "Nevratná akce",
                    foregroundColor: .red,
                    background: .tinted(.red),
                    action: onUnlock
                )
            ],
            height: 320
        )
    }
}

#if DEBUG
#Preview("Committed Unlock") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            CommittedUnlockSheet(onUnlock: { print("Unlock") })
        }
}
#endif
