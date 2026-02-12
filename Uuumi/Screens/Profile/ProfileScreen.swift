import SwiftUI
import Supabase

enum ProfileDestination: Hashable {
    case essenceCatalog
    case notificationSettings
    case shieldSettings
}

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(AuthManager.self) private var authManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(SyncManager.self) private var syncManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .automatic
    @AppStorage("selectedDayTheme") private var dayTheme: DayTheme = .morningHaze
    @AppStorage("selectedNightTheme") private var nightTheme: NightTheme = .deepNight
    @AppStorage("lockButtonSide") private var lockButtonSide: LockButtonSide = .trailing
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var showPremiumSheet = false
    @State private var showAuthSheet = false
    @State private var showAccountSheet = false
    @State private var pendingSignOut = false
    @Binding var navigationPath: NavigationPath

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                // MARK: - Profile Header
                Section {
                    profileHeader
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // MARK: - Účet
                Section(header: Text("Účet")) {
                    if authManager.isAuthenticated {
                        Button {
                            showAccountSheet = true
                        } label: {
                            Label("Účet", systemImage: "person")
                        }
                        .tint(.primary)
                    }

                    Button {
                        showPremiumSheet = true
                    } label: {
                        HStack {
                            Label("Uuumium", systemImage: "crown.fill")
                                .foregroundStyle(Color("PremiumGold"))
                            if storeManager.isPremium {
                                Spacer()
                                Text("Aktivní")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color("PremiumGold"))
                            }
                        }
                    }

                    NavigationLink(value: ProfileDestination.essenceCatalog) {
                        HStack {
                            Label("Katalog Essencí", systemImage: "sparkles")
                            Spacer()
                            Text("\(catalogManager.unlockedEssences.count)/\(Essence.allCases.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Přizpůsobit
                Section(header: Text("Přizpůsobit")) {
                    NavigationLink(value: ProfileDestination.notificationSettings) {
                        HStack {
                            Label("Notifikace", systemImage: "bell.fill")
                            Spacer()
                            Text(limitSettings.notifications.masterEnabled ? "Zapnuto" : "Vypnuto")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink(value: ProfileDestination.shieldSettings) {
                        Label("Shield", systemImage: "shield.fill")
                    }

                    Picker(selection: $lockButtonSide) {
                        ForEach(LockButtonSide.allCases, id: \.self) { side in
                            Text(side.label).tag(side)
                        }
                    } label: {
                        Label("Lock tlačítko", systemImage: "lock.fill")
                    }

                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    } label: {
                        Label("Vzhled", systemImage: "paintbrush.fill")
                    }

                    switch appearanceMode {
                    case .automatic:
                        EmptyView()
                    case .light:
                        ThemePicker(
                            themes: DayTheme.allCases,
                            selected: $dayTheme,
                            label: \.label,
                            gradient: \.gradient
                        )
                    case .dark:
                        ThemePicker(
                            themes: NightTheme.allCases,
                            selected: $nightTheme,
                            label: \.label,
                            gradient: \.gradient
                        )
                    }

                }

                // MARK: - Pomoc
                Section(header: Text("Pomoc")) {
                    HStack {
                        Label("Verze", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    if authManager.isAuthenticated {
                        syncStatusRow
                    }

                    Link(destination: URL(string: "mailto:support@uuumi.app")!) {
                        Label("Napsat podporu", systemImage: "envelope")
                    }
                }

                #if DEBUG
                Section(header: Text("Debug")) {
                    Button("Delete Active Pet", role: .destructive) {
                        deleteActivePet()
                    }
                    .disabled(!petManager.hasPet)

                    Button("Simulate Daily Reset") {
                        SharedDefaults.resetForNewDay(dayStartShieldEnabled: limitSettings.dayStartShieldEnabled)
                        ShieldManager.shared.activateStoreFromStoredTokens()
                    }
                }
                #endif
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPremiumSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "u.circle.fill")
                                .foregroundStyle(Color("PremiumGold"))
                            Text("\(SharedDefaults.coinsBalance)")
                                .fontWeight(.semibold)
                        }
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
            .fullScreenCover(isPresented: $showAuthSheet) {
                AuthProvidersSheet()
            }
            .fullScreenCover(isPresented: $showAccountSheet, onDismiss: {
                if pendingSignOut {
                    pendingSignOut = false
                    Task { await authManager.signOut() }
                }
            }) {
                AccountScreen(onSignOut: { pendingSignOut = true })
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .essenceCatalog:
                    EssenceCatalogScreen()
                case .notificationSettings:
                    NotificationSettingsScreen()
                case .shieldSettings:
                    ShieldSettingsScreen()
                }
            }
            .onChange(of: limitSettings) { _, newValue in
                SharedDefaults.limitSettings = newValue
            }
            .alert("Chyba", isPresented: hasAuthError, presenting: authManager.error) { _ in
                Button("OK") { authManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Profile Header

    @ViewBuilder
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar — tappable to account/auth
            Button {
                if authManager.isAuthenticated {
                    showAccountSheet = true
                } else {
                    showAuthSheet = true
                }
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(authManager.isAuthenticated ? .secondary : Color(.systemGray3))
            }
            .buttonStyle(.plain)

            // Name / subtitle
            VStack(spacing: 4) {
                if authManager.isAuthenticated {
                    Text(displayName)
                        .font(.title3.weight(.bold))
                    if let createdAt = authManager.currentUser?.createdAt {
                        Text("Členem od \(createdAt.formatted(.dateTime.month(.wide).year()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Host")
                        .font(.title3.weight(.bold))
                    Text("Ahoj, hoste! Pojďme se lépe poznat.\nVytvoř si účet, nebo se přihlas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // CTA button (only when not authenticated)
            if !authManager.isAuthenticated {
                Button {
                    showAuthSheet = true
                } label: {
                    Text("Register / Login")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }   
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var displayName: String {
        if let name = authManager.currentUser?.userMetadata["full_name"],
           case .string(let value) = name, !value.isEmpty {
            return value
        }
        return authManager.userEmail?.components(separatedBy: "@").first ?? "Uživatel"
    }

    private var hasAuthError: Binding<Bool> {
        Binding(
            get: { authManager.error != nil },
            set: { if !$0 { authManager.clearError() } }
        )
    }

    @ViewBuilder
    private var syncStatusRow: some View {
        HStack {
            if syncManager.isSyncing {
                Label("Synchronizace...", systemImage: "arrow.triangle.2.circlepath")
            } else if syncManager.lastError != nil {
                Label("Sync selhal", systemImage: "exclamationmark.icloud")
                    .foregroundStyle(.orange)
            } else {
                Label("Synchronizace", systemImage: "checkmark.icloud")
            }
            Spacer()
            if syncManager.isSyncing {
                ProgressView()
                    .controlSize(.mini)
            } else if let date = syncManager.lastSyncDate {
                Text(date.formatted(.relative(presentation: .named)))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    #if DEBUG
    private func deleteActivePet() {
        if let pet = petManager.currentPet {
            petManager.delete(id: pet.id)
        }
    }
    #endif
}

// MARK: - Theme Picker

private struct ThemePicker<T: Hashable & Identifiable>: View {
    let themes: [T]
    @Binding var selected: T
    let label: KeyPath<T, String>
    let gradient: KeyPath<T, [Color]>

    var body: some View {
        HStack(spacing: 12) {
            ForEach(themes) { theme in
                let isSelected = theme.id == selected.id
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: theme[keyPath: gradient],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2.5)
                        )

                    Text(theme[keyPath: label])
                        .font(.caption)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = theme
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileScreen(navigationPath: .constant(NavigationPath()))
        .environment(PetManager.mock())
        .environment(EssenceCatalogManager.mock())
        .environment(AuthManager.mock())
        .environment(StoreManager.mock())
        .environment(SyncManager())
}
