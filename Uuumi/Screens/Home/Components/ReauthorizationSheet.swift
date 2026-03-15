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
                title: "\(petName) doesn't have app access",
                subtitle: "Screen Time access was revoked. If you allow it again, \(petName) can continue living."
            )

            VStack(spacing: 12) {
                ConfirmationAction(
                    icon: "checkmark.shield",
                    title: "Allow again",
                    subtitle: "Restores access and monitoring",
                    foregroundColor: .green,
                    background: .tinted(.green),
                    action: onReauthorize
                )

                ConfirmationAction(
                    icon: "wind",
                    title: "Let go",
                    subtitle: "\(petName) will be archived as lost",
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
