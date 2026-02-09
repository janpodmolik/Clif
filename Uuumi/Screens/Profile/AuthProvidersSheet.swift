import SwiftUI
import AuthenticationServices

struct AuthProvidersSheet: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var showEmailAuth = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Title
                Text("Začni s ")
                    .font(.title.weight(.bold)) +
                Text("Uuumim")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color(.label))

                Spacer()

                // Provider buttons
                VStack(spacing: 12) {
                    appleSignInButton
                    googleSignInButton
                    emailButton
                }
                .padding(.horizontal, 24)

                // Legal footer
                legalFooter
                    .padding(.top, 24)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .dismissButton()
            .alert("Chyba", isPresented: hasError, presenting: authManager.error) { _ in
                Button("OK") { authManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
            .fullScreenCover(isPresented: $showEmailAuth, onDismiss: {
                if authManager.isAuthenticated { dismiss() }
            }) {
                EmailAuthScreen()
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            if isAuth && !isLoading { dismiss() }
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInButton: some View {
        SignInWithAppleButton(.continue) { request in
            authManager.configureAppleSignIn(request: request)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                Task { await authManager.handleAppleSignIn(authorization: authorization) }
            case .failure:
                break
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 54)
        .clipShape(Capsule())
    }

    // MARK: - Google Sign In

    private var googleSignInButton: some View {
        Button {
            Task {
                isLoading = true
                await authManager.signInWithGoogle()
                isLoading = false
                if authManager.isAuthenticated { dismiss() }
            }
        } label: {
            HStack(spacing: 12) {
                Image("google-logo")
                    .resizable()
                    .frame(width: 22, height: 22)
                Text("Pokračovat přes Google")
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.tertiarySystemFill))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }

    // MARK: - Email Button

    private var emailButton: some View {
        Button {
            showEmailAuth = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.body)
                Text("Pokračovat e-mailem")
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.tertiarySystemFill))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Legal Footer

    // TODO: Make legal links tappable once privacy policy & terms pages are live
    private var legalFooter: some View {
        (Text("Pokračováním souhlasíš se ") +
        Text("Zásadami ochrany osobních údajů")
            .underline() +
        Text(" a ") +
        Text("Podmínkami používání")
            .underline())
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var hasError: Binding<Bool> {
        Binding(
            get: { authManager.error != nil },
            set: { if !$0 { authManager.clearError() } }
        )
    }
}

#Preview {
    AuthProvidersSheet()
        .environment(AuthManager.mock())
}
