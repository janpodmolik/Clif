import SwiftUI

/// Confirmation sheet for voluntarily blowing away the current pet.
struct BlowAwaySheet: View {
    var onBlowAway: () -> Void = {}

    var body: some View {
        ConfirmationSheet(
            navigationTitle: "Odfoukout peta?",
            header: ConfirmationSheetHeader(
                icon: "wind",
                iconColor: .red,
                title: "Odfoukout peta?",
                subtitle: "Tvůj pet bude odfouknut a budeš muset začít znovu. Tato akce je nevratná."
            ),
            actions: [
                ConfirmationSheetAction(
                    icon: "wind",
                    title: "Odfoukout",
                    subtitle: "Nevratná akce",
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
