import SwiftUI
import Supabase

struct AccountScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
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
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }   
            }
            .onAppear {
                if let name = authManager.currentUser?.userMetadata["full_name"],
                   case .string(let value) = name {
                    displayName = value
                }
            }
        }
    }
}

#Preview {
    AccountScreen()
        .environment(AuthManager.mock())
}
