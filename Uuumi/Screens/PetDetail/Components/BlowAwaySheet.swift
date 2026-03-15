import SwiftUI

/// Confirmation sheet for voluntarily blowing away the current pet.
struct BlowAwaySheet: View {
    var onBlowAway: () -> Void = {}

    var body: some View {
        ConfirmationSheet(
            navigationTitle: "Blow away pet?",
            header: ConfirmationSheetHeader(
                icon: "wind",
                iconColor: .red,
                title: "Blow away pet?",
                subtitle: "Your pet will be blown away and you'll have to start over. This action is irreversible."
            ),
            actions: [
                ConfirmationSheetAction(
                    icon: "wind",
                    title: "Blow Away",
                    subtitle: "Irreversible action",
                    foregroundColor: .red,
                    background: .tinted(.red),
                    action: onBlowAway
                )
            ],
            height: 300
        )
    }
}

#if DEBUG
#Preview("Blow Away") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            BlowAwaySheet(onBlowAway: { print("Blow away") })
        }
}
#endif
