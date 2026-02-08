import SwiftUI
import Supabase

struct AccountScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    var onSignOut: (() -> Void)?

    @State private var displayName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.secondary)

                    // TODO: Implement avatar photo picker
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.accentColor, in: Circle())
                        .offset(x: 4, y: 4)
                }
                .padding(.top, 16)

                // Display name (editable)
                TextField("Jméno", text: $displayName)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

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
                    onSignOut?()
                    dismiss()
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
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Účet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // TODO: Save display name to Supabase user metadata
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
