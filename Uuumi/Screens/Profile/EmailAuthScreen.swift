import SwiftUI

struct EmailAuthScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showPasswordReset = false
    @State private var resetEmail = ""
    @State private var showResetConfirmation = false
    @State private var localError: String?
    @State private var showConfirmationInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text(isSignUp ? "Create an Account" : "Sign In")
                            .font(.title.weight(.bold))
                        Text(isSignUp
                             ? "Enter your email and password to sign up."
                             : "Enter your email and password.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Form
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Password", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                                )

                            if isSignUp {
                                Text("At least 8 characters")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 16)
                            }
                        }

                        Button {
                            Task {
                                isLoading = true
                                authManager.clearError()
                                if isSignUp {
                                    let result = await authManager.signUpWithEmail(email, password: password)
                                    isLoading = false
                                    switch result {
                                    case .confirmationRequired:
                                        showConfirmationInfo = true
                                    case .emailAlreadyUsed:
                                        localError = String(localized: "This email is already registered. Try signing in.")
                                    case .success:
                                        break // onChange(of: isAuthenticated) handles dismiss
                                    case nil:
                                        if let error = authManager.error {
                                            localError = error.localizedDescription
                                            authManager.clearError()
                                        }
                                    }
                                } else {
                                    await authManager.signInWithEmail(email, password: password)
                                    isLoading = false
                                    if let error = authManager.error {
                                        localError = error.localizedDescription
                                        authManager.clearError()
                                    }
                                }
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(Color(.systemBackground))
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid)
                        .padding(.top, 4)

                        HStack {
                            Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                                withAnimation { isSignUp.toggle() }
                            }
                            .font(.caption)

                            Spacer()

                            if !isSignUp {
                                Button("Forgot Password?") {
                                    resetEmail = email
                                    showPasswordReset = true
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .dismissButton(placement: .topBarTrailing)
            .alert("Error", isPresented: hasLocalError) {
                Button("OK") { localError = nil }
            } message: {
                Text(localError ?? "")
            }
            .alert("Verify Your Email", isPresented: $showConfirmationInfo) {
                Button("OK") { dismiss() }
            } message: {
                Text("We sent a confirmation link to \(email). Click on it and then sign in.")
            }
            .alert("Link Sent", isPresented: $showResetConfirmation) {
                Button("OK") { }
            } message: {
                Text("A password reset link has been sent to \(resetEmail).")
            }
            .sheet(isPresented: $showPasswordReset) {
                passwordResetSheet
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Password Reset Sheet

    private var passwordResetSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $resetEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                } footer: {
                    Text("We'll send you a password reset link.")
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPasswordReset = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            await authManager.resetPassword(email: resetEmail)
                            showPasswordReset = false
                            showResetConfirmation = true
                        }
                    }
                    .disabled(resetEmail.isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !email.isEmpty && password.count >= 8 && !isLoading
    }

    private var hasLocalError: Binding<Bool> {
        Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )
    }
}

#Preview {
    EmailAuthScreen()
        .environment(AuthManager.mock())
}
