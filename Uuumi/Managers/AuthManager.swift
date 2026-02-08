import Foundation
import UIKit
import Supabase
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
final class AuthManager {

    // MARK: - Types

    enum AuthState: Equatable {
        case loading
        case anonymous
        case authenticated(User)

        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.anonymous, .anonymous):
                return true
            case (.authenticated(let a), .authenticated(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }

    enum SignUpResult {
        case success
        case confirmationRequired
        case emailAlreadyUsed
    }

    enum AuthError: LocalizedError {
        case invalidCredential
        case missingNonce
        case missingIdentityToken
        case supabase(Error)

        var errorDescription: String? {
            switch self {
            case .invalidCredential:
                return "Neplatné přihlašovací údaje"
            case .missingNonce:
                return "Chyba při přihlašování (chybí nonce)"
            case .missingIdentityToken:
                return "Nelze získat Apple identity token"
            case .supabase(let error):
                return error.localizedDescription
            }
        }
    }

    // MARK: - State

    private(set) var authState: AuthState = .loading
    private(set) var error: AuthError?

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var currentUser: User? {
        if case .authenticated(let user) = authState { return user }
        return nil
    }

    var userEmail: String? {
        currentUser?.email
    }

    var authProvider: String? {
        guard let provider = currentUser?.appMetadata["provider"] else { return nil }
        if case .string(let value) = provider { return value }
        return nil
    }

    // MARK: - Private

    private var currentNonce: String?
    private var authStateTask: Task<Void, Never>?
    private var client: SupabaseClient { SupabaseConfig.client }

    // MARK: - Init

    init() {
        startAuthStateObservation()
    }

    // MARK: - Auth State Observation

    private func startAuthStateObservation() {
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session {
                        self.authState = .authenticated(session.user)
                    } else {
                        self.authState = .anonymous
                    }
                case .signedIn:
                    if let session {
                        self.authState = .authenticated(session.user)
                    }
                case .signedOut:
                    self.authState = .anonymous
                case .tokenRefreshed:
                    if let session {
                        self.authState = .authenticated(session.user)
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Apple Sign In

    func configureAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        let nonce = generateNonce()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(authorization: ASAuthorization) async {
        error = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            error = .invalidCredential
            return
        }
        guard let nonce = currentNonce else {
            error = .missingNonce
            return
        }
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            error = .missingIdentityToken
            return
        }

        do {
            try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString,
                    nonce: nonce
                )
            )
        } catch {
            self.error = .supabase(error)
        }

        currentNonce = nil
    }

    // MARK: - Google Sign In (OAuth via ASWebAuthenticationSession)

    func signInWithGoogle() async {
        error = nil
        do {
            let oauthURL = try await client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "uuumi://auth/callback"),
                queryParams: [(name: "prompt", value: "select_account")]
            )

            let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: oauthURL,
                    callbackURLScheme: "uuumi"
                ) { url, error in
                    if let url {
                        continuation.resume(returning: url)
                    } else if let error {
                        continuation.resume(throwing: error)
                    }
                }
                session.prefersEphemeralWebBrowserSession = false
                session.presentationContextProvider = OAuthPresentationContext.shared
                session.start()
            }

            _ = try await client.auth.session(from: callbackURL)
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // User cancelled — do nothing
        } catch {
            self.error = .supabase(error)
        }
    }

    // MARK: - Email + Password

    func signUpWithEmail(_ email: String, password: String) async -> SignUpResult? {
        error = nil
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            if response.user.identities?.isEmpty ?? true {
                return .emailAlreadyUsed
            }
            if response.session != nil {
                return .success
            }
            return .confirmationRequired
        } catch {
            self.error = .supabase(error)
            return nil
        }
    }

    func signInWithEmail(_ email: String, password: String) async {
        error = nil
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            self.error = .supabase(error)
        }
    }

    func resetPassword(email: String) async {
        error = nil
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            self.error = .supabase(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        error = nil
        do {
            try await client.auth.signOut()
        } catch {
            self.error = .supabase(error)
        }
    }

    // MARK: - Delete Account

    /// Deletes the current user via a Supabase database function.
    /// Requires a `delete_user()` SQL function with `SECURITY DEFINER` on the backend.
    func deleteAccount() async -> Bool {
        error = nil
        do {
            try await client.rpc("delete_user").execute()
            try await client.auth.signOut()
            return true
        } catch {
            self.error = .supabase(error)
            return false
        }
    }

    // MARK: - OAuth Callback

    func handleOAuthCallback(url: URL) {
        client.auth.handle(url)
    }

    // MARK: - Clear Error

    func clearError() {
        error = nil
    }

    // MARK: - Nonce Helpers

    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. OSStatus: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - OAuth Presentation Context

private final class OAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

// MARK: - Preview Support

extension AuthManager {
    static func mock() -> AuthManager {
        let manager = AuthManager()
        manager.authState = .anonymous
        manager.authStateTask?.cancel()
        manager.authStateTask = nil
        return manager
    }
}
