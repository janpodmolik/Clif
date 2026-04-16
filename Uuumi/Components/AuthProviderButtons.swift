import AuthenticationServices
import SwiftUI

struct AuthProviderButtons: View {
    var onAuthenticated: (() -> Void)?

    @Environment(AuthManager.self) private var authManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var showEmailAuth = false
    @State private var wasAuthenticated = false
    @State private var didCallBack = false

    var body: some View {
        VStack(spacing: 12) {
            appleSignInButton
            googleSignInButton
            emailButton

            legalFooter
                .padding(.top, 8)
        }
        .alert("Error", isPresented: hasError, presenting: authManager.error) { _ in
            Button("OK") { authManager.clearError() }
        } message: { error in
            Text(error.localizedDescription)
        }
        .fullScreenCover(isPresented: $showEmailAuth) {
            EmailAuthScreen()
        }
        .onAppear {
            wasAuthenticated = authManager.isAuthenticated
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            // Handles email auth (returns from fullScreenCover) and
            // first-time sign-in via Apple/Google when onChange fires.
            if isAuth {
                handleAuthCompleted()
            }
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInButton: some View {
        SignInWithAppleButton(.continue) { request in
            authManager.configureAppleSignIn(request: request)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                Task {
                    await authManager.handleAppleSignIn(authorization: authorization)
                    // Covers re-auth when already signed in (onChange won't fire)
                    if authManager.isAuthenticated { handleAuthCompleted() }
                }
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
                // Covers re-auth when already signed in (onChange won't fire)
                if authManager.isAuthenticated { handleAuthCompleted() }
            }
        } label: {
            HStack(spacing: 12) {
                Image("google-logo")
                    .resizable()
                    .frame(width: 22, height: 22)
                Text("Continue with Google")
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                Text("Continue with Email")
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        legalText
            .font(.caption)
            .foregroundStyle(.primary.opacity(0.6))
            .tint(.primary.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }

    private var legalText: Text {
        Text("By continuing, you agree to the ") +
        Text("[Privacy Policy](https://uuumi.app/privacy/)")
            .underline() +
        Text(" and ") +
        Text("[Terms of Service](https://uuumi.app/terms/)")
            .underline() +
        Text(".")
    }

    // MARK: - Helpers

    private func handleAuthCompleted() {
        guard !didCallBack else { return }
        didCallBack = true
        if !wasAuthenticated {
            analytics.send(.authCompleted(method: authManager.authProvider ?? "unknown"))
        }
        onAuthenticated?()
    }

    private var hasError: Binding<Bool> {
        Binding(
            get: { authManager.error != nil },
            set: { if !$0 { authManager.clearError() } }
        )
    }
}
