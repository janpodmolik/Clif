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
                TextField("Jméno", text: $displayName)
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
                    Text("Odhlásit se")
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
                        Text("Smazat účet")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .disabled(isDeleting)
                .confirmationDialog(
                    "Opravdu chceš smazat účet?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Smazat účet", role: .destructive) {
                        Task {
                            isDeleting = true
                            let success = await authManager.deleteAccount()
                            isDeleting = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    Button("Zrušit", role: .cancel) { }
                } message: {
                    Text("Tato akce je nevratná. Všechna data spojená s účtem budou smazána.")
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Účet")
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
