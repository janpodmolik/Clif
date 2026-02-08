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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )

                        SecureField("Heslo", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )

                        Button {
                            Task {
                                isLoading = true
                                if isSignUp {
                                    await authManager.signUpWithEmail(email, password: password)
                                } else {
                                    await authManager.signInWithEmail(email, password: password)
                                }
                                isLoading = false
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text(isSignUp ? "Zaregistrovat se" : "Přihlásit se")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.count < 6 || isLoading)
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
            .alert("Chyba", isPresented: hasError, presenting: authManager.error) { _ in
                Button("OK") { authManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
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

    private var hasError: Binding<Bool> {
        Binding(
            get: { authManager.error != nil },
            set: { if !$0 { authManager.clearError() } }
        )
    }
}

#Preview {
    EmailAuthScreen()
        .environment(AuthManager.mock())
}
