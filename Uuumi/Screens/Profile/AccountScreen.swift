import SwiftUI
import Supabase

struct AccountScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(DefaultsKeys.gender) private var gender: Gender = .notSpecified
    @State private var displayName: String = ""
    @State private var initialDisplayName: String = ""
    @State private var isSavingName = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Display name (editable)
                TextField("Name", text: $displayName)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Email
                if let email = authManager.userEmail {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Text(email)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                }

                // Gender
                VStack(spacing: 6) {
                    Picker("Gender", selection: $gender) {
                        Text("Prefer not to say").tag(Gender.notSpecified)
                        Text("Male").tag(Gender.male)
                        Text("Female").tag(Gender.female)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    Text("Helps us decide which pet evolutions and assets to create next.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Sign out
                Button {
                    dismiss()
                    Task { await authManager.signOut() }
                } label: {
                    Text("Sign Out")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
                .tint(.blue)
                .padding(.top, 4)

                Spacer()

                // Delete account
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        ProgressView()
                    } else {
                        Text("Delete Account")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .disabled(isDeleting)
                .confirmationDialog(
                    "Are you sure you want to delete your account?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Account", role: .destructive) {
                        Task {
                            isDeleting = true
                            let success = await authManager.deleteAccount()
                            isDeleting = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action is irreversible. All data associated with the account will be deleted.")
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await saveAndDismiss() }
                    } label: {
                        if isSavingName {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(isSavingName)
                }
            }
            .onAppear {
                if let name = authManager.currentUser?.userMetadata["full_name"],
                   case .string(let value) = name {
                    displayName = value
                    initialDisplayName = value
                }
            }
            .alert(
                String(localized: "Couldn't save"),
                isPresented: hasAuthError,
                presenting: authManager.error
            ) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    private var hasAuthError: Binding<Bool> {
        Binding(
            get: { authManager.error != nil },
            set: { if !$0 { authManager.clearError() } }
        )
    }

    private func saveAndDismiss() async {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != initialDisplayName.trimmingCharacters(in: .whitespacesAndNewlines) else {
            dismiss()
            return
        }
        isSavingName = true
        let success = await authManager.updateDisplayName(trimmed)
        isSavingName = false
        if success {
            dismiss()
        }
    }
}

#Preview {
    AccountScreen()
        .environment(AuthManager.mock())
}
