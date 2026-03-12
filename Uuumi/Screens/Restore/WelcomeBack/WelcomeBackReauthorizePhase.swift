import FamilyControls
import SwiftUI

struct WelcomeBackReauthorizePhase: View {
    let petName: String
    let onAuthorized: () -> Void
    let onBack: () -> Void

    @State private var isAuthorizing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                Text("\(petName) je zpátky!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Po reinstalaci je potřeba znovu povolit přístup k času u obrazovky a vybrat sledované aplikace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            WelcomeBackActionButton(
                icon: "checkmark.shield",
                title: "Znovu povolit",
                subtitle: "Povolí přístup a umožní výběr aplikací",
                iconColor: nil,
                isLoading: isAuthorizing,
                action: { Task { await authorize() } }
            )

            Spacer()
        }
        .padding(24)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zpět", action: onBack)
            }
        }
    }

    private func authorize() async {
        isAuthorizing = true
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            onAuthorized()
        } catch {
            // Authorization failed — stay on this phase, user can retry
        }
        isAuthorizing = false
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WelcomeBackReauthorizePhase(
            petName: "Kořen",
            onAuthorized: {},
            onBack: {}
        )
    }
}
#endif
