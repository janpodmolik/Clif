import SwiftUI

// MARK: - Temporarily disabled (Supabase server not running)
// TODO: Uncomment when Supabase backend is ready

/*
import Supabase
import Auth

// TODO: Pokračovat s implementací autentizace (login/signup flow, session persistence)

struct SupabaseTestView: View {

    // MARK: - State

    @State private var isAuthenticated = false
    @State private var currentUser: User?
    @State private var profile: Profile?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCreateProfile = false
    @State private var showAuthSheet = false
    @State private var authTask: Task<Void, Never>?

    private var client = SupabaseConfig.client

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                statusSection

                Divider()

                if let profile {
                    profileSection(profile)
                } else if isLoading {
                    ProgressView("Načítám profil...")
                } else {
                    noProfileSection
                }

                Spacer()

                actionsSection
            }
            .padding()
            .navigationTitle("Supabase Test")
            .alert("Chyba", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCreateProfile) {
                CreateProfileSheet(onCreate: createProfile)
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthSheet(onAuth: signIn, onSignUp: signUp)
            }
            .task {
                await observeAuthState()
            }
            .onDisappear {
                authTask?.cancel()
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        HStack {
            Circle()
                .fill(isAuthenticated ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            Text(isAuthenticated ? "Přihlášen" : "Nepřihlášen")
                .font(.headline)

            Spacer()

            if let user = currentUser {
                Text(user.email ?? "—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func profileSection(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profil")
                .font(.headline)

            HStack {
                Text("Username:")
                    .foregroundColor(.secondary)
                Text(profile.username)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Vytvořeno:")
                    .foregroundColor(.secondary)
                Text(profile.createdAt, style: .date)
            }

            HStack {
                Text("ID:")
                    .foregroundColor(.secondary)
                Text(profile.id.uuidString.prefix(8) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var noProfileSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Žádný profil")
                .font(.headline)

            if isAuthenticated {
                Button("Vytvořit profil") {
                    showCreateProfile = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if isAuthenticated {
                Button("Načíst profil") {
                    Task { await fetchProfile() }
                }
                .buttonStyle(.bordered)

                Button("Odhlásit se", role: .destructive) {
                    Task { await signOut() }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Přihlásit se") {
                    showAuthSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Actions

extension SupabaseTestView {

    private func observeAuthState() async {
        for await state in client.auth.authStateChanges {
            switch state.event {
            case .initialSession, .signedIn:
                currentUser = state.session?.user
                isAuthenticated = state.session != nil

                if isAuthenticated {
                    await fetchProfile()
                }

            case .signedOut:
                currentUser = nil
                isAuthenticated = false
                profile = nil

            default:
                break
            }
        }
    }

    private func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            handleError(error)
        }
    }

    private func signUp(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(email: email, password: password)
            _ = response.user.id
        } catch {
            handleError(error)
        }
    }

    private func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            handleError(error)
        }
    }

    private func fetchProfile() async {
        guard let userId = client.auth.currentUser?.id else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedProfile: Profile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            profile = fetchedProfile
        } catch {
            profile = nil
        }
    }

    private func createProfile(username: String) async {
        guard let userId = client.auth.currentUser?.id else {
            handleError(ProfileError.notAuthenticated)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await client
                .from("profiles")
                .insert(["id": userId.uuidString, "username": username])
                .execute()

            await fetchProfile()
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Auth Sheet

struct AuthSheet: View {
    let onAuth: (String, String) async -> Void
    let onSignUp: (String, String) async -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)

                SecureField("Heslo", text: $password)

                Toggle("Registrace", isOn: $isSignUp)
            }
            .navigationTitle(isSignUp ? "Registrace" : "Přihlášení")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSignUp ? "Registrovat" : "Přihlásit") {
                        Task {
                            if isSignUp {
                                await onSignUp(email, password)
                            } else {
                                await onAuth(email, password)
                            }
                            dismiss()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

// MARK: - Create Profile Sheet

struct CreateProfileSheet: View {
    let onCreate: (String) async -> Void

    @State private var username = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .navigationTitle("Nový profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Vytvořit") {
                        Task {
                            await onCreate(username)
                            dismiss()
                        }
                    }
                    .disabled(username.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SupabaseTestView()
}
*/

// MARK: - Placeholder view while Supabase is disabled

struct SupabaseTestView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Supabase Disabled")
                .font(.headline)

            Text("Backend server is not running.\nUncomment code in SupabaseConfig.swift to enable.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Supabase Test")
    }
}

#Preview {
    SupabaseTestView()
}
