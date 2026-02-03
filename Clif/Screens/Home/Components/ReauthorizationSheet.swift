import SwiftUI

/// Sheet shown when Screen Time authorization is lost.
/// Offers re-authorization or archiving the pet as lost.
/// Non-dismissable — user must pick one of the two options.
struct ReauthorizationSheet: View {
    let petName: String
    let onReauthorize: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            ConfirmationHeader(
                icon: "exclamationmark.triangle",
                iconColor: .orange,
                title: "\(petName) nemá přístup k aplikacím",
                subtitle: "Přístup k času u obrazovky byl odebrán. Pokud ho znovu povolíš, \(petName) může žít dál."
            )

            VStack(spacing: 12) {
                ConfirmationAction(
                    icon: "checkmark.shield",
                    title: "Znovu povolit",
                    subtitle: "Obnoví přístup a monitoring",
                    foregroundColor: .green,
                    background: .tinted(.green),
                    action: onReauthorize
                )

                ConfirmationAction(
                    icon: "wind",
                    title: "Nechat odejít",
                    subtitle: "\(petName) bude archivován jako ztracený",
                    foregroundColor: .red,
                    background: .tinted(.red),
                    action: onDecline
                )
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }
}

#if DEBUG
#Preview {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            ReauthorizationSheet(
                petName: "Fern",
                onReauthorize: { print("Re-authorize") },
                onDecline: { print("Decline") }
            )
        }
}
#endif
