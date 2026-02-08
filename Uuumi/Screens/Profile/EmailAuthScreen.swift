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
                        Text(isSignUp ? "Vytvoř si účet" : "Přihlásit se")
                            .font(.title.weight(.bold))
                        Text(isSignUp
                             ? "Zadej svůj email a heslo pro registraci."
                             : "Zadej svůj email a heslo.")
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
                            SecureField("Heslo", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                                )

                            if isSignUp {
                                Text("Minimálně 8 znaků")
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
                                        localError = "Tento email je již registrovaný. Zkus se přihlásit."
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
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text(isSignUp ? "Zaregistrovat se" : "Přihlásit se")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .foregroundStyle(isFormValid ? .white : Color(.tertiaryLabel))
                        .background(isFormValid ? Color.accentColor : Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                        .disabled(!isFormValid)
                        .padding(.top, 4)

                        HStack {
                            Button(isSignUp ? "Už máš účet? Přihlásit se" : "Nemáš účet? Zaregistrovat se") {
                                withAnimation { isSignUp.toggle() }
                            }
                            .font(.caption)

                            Spacer()

                            if !isSignUp {
                                Button("Zapomenuté heslo?") {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Chyba", isPresented: hasLocalError) {
                Button("OK") { localError = nil }
            } message: {
                Text(localError ?? "")
            }
            .alert("Ověř svůj email", isPresented: $showConfirmationInfo) {
                Button("OK") { dismiss() }
            } message: {
                Text("Poslali jsme ti potvrzovací odkaz na \(email). Klikni na něj a pak se přihlas.")
            }
            .alert("Odkaz odeslán", isPresented: $showResetConfirmation) {
                Button("OK") { }
            } message: {
                Text("Odkaz pro reset hesla byl odeslán na \(resetEmail).")
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
                    Text("Pošleme ti odkaz pro reset hesla.")
                }
            }
            .navigationTitle("Reset hesla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { showPasswordReset = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Odeslat") {
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
