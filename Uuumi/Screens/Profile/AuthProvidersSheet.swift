import SwiftUI

struct AuthProvidersSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Title
                Text("Get started with ")
                    .font(.title.weight(.bold)) +
                Text("Uuumi")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color(.label))

                Spacer()

                AuthProviderButtons {
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .dismissButton()
        }
    }
}

#Preview {
    AuthProvidersSheet()
        .environment(AuthManager.mock())
        .environment(AnalyticsManager())
}
