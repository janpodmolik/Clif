import FamilyControls
import Supabase
import SwiftUI

enum ProfileDestination: Hashable {
    case essenceCatalog
    case notificationSettings
    case shieldSettings
    case dailyPresetSettings
    case lockButtonSettings
    case feedback
}

struct ProfileScreen: View {
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(AuthManager.self) private var authManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(SyncManager.self) private var syncManager
    @AppStorage(DefaultsKeys.appearanceMode) private var appearanceMode: AppearanceMode = .automatic
    @AppStorage(DefaultsKeys.selectedDayTheme) private var dayTheme: DayTheme = .morningHaze
    @AppStorage(DefaultsKeys.selectedNightTheme) private var nightTheme: NightTheme = .deepNight
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var showPremiumSheet = false
    @State private var showCoinShopSheet = false
    @State private var showAuthSheet = false
    @State private var showAccountSheet = false
    @State private var showMyAppsSheet = false
    @State private var showFeedbackSuccess = false
    @State private var myAppsSelection: FamilyActivitySelection?
    @Binding var navigationPath: NavigationPath

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                // MARK: - Profile
                Section {
                    profileRow
                }

                // MARK: - Účet
                Section(header: Text("Account")) {
                    Button {
                        showPremiumSheet = true
                    } label: {
                        HStack {
                            Label("Uuumium", systemImage: "crown.fill")
                                .foregroundStyle(Color("PremiumGold"))
                            if storeManager.isPremium {
                                Spacer()
                                Text("Active")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color("PremiumGold"))
                            }
                        }
                    }

                    NavigationLink(value: ProfileDestination.essenceCatalog) {
                        HStack {
                            Label("Essence Catalog", systemImage: "sparkles")
                            Spacer()
                            Text("\(catalogManager.allUnlocked.count)/\(Essence.allCases.count)")
                                .foregroundStyle(.secondary)
                        }
                    }

                }

                // MARK: - Přizpůsobit
                Section(header: Text("Customize")) {
                    NavigationLink(value: ProfileDestination.notificationSettings) {
                        HStack {
                            Label("Notifications", systemImage: "bell.fill")
                            Spacer()
                            Text(limitSettings.notifications.masterEnabled ? "On" : "Off")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink(value: ProfileDestination.shieldSettings) {
                        Label("Shield", systemImage: "shield.fill")
                    }

                    NavigationLink(value: ProfileDestination.lockButtonSettings) {
                        Label("Lock Button", systemImage: "lock.fill")
                    }

                    NavigationLink(value: ProfileDestination.dailyPresetSettings) {
                        HStack {
                            Label("Daily Preset", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Text((WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced).displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    } label: {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }

                    switch appearanceMode {
                    case .automatic:
                        EmptyView()
                    case .light:
                        ThemePicker(
                            themes: DayTheme.allCases,
                            selected: $dayTheme,
                            label: \.label,
                            gradient: \.gradient,
                            isPremium: \.isPremium
                        )
                    case .dark:
                        ThemePicker(
                            themes: NightTheme.allCases,
                            selected: $nightTheme,
                            label: \.label,
                            gradient: \.gradient,
                            isPremium: \.isPremium
                        )
                    }

                }

                // MARK: - Moje aplikace
                Section(header: Text("My Apps")) {
                    Button {
                        showMyAppsSheet = true
                    } label: {
                        if let selection = myAppsSelection {
                            HStack(spacing: 8) {
                                Label("Saved Selection", systemImage: "app.dashed")
                                Spacer()
                                LimitedSourcesPreview(
                                    applicationTokens: Array(selection.applicationTokens),
                                    categoryTokens: selection.categoryTokens,
                                    webDomainTokens: selection.webDomainTokens,
                                    compact: true
                                )
                            }
                        } else {
                            Label("No Saved Selection", systemImage: "app.dashed")
                        }
                    }
                }

                // MARK: - Pomoc
                Section(header: Text("Help")) {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    if authManager.isAuthenticated {
                        syncStatusRow
                    }

                    NavigationLink(value: ProfileDestination.feedback) {
                        Label("Feedback", systemImage: "text.bubble")
                    }
                }

            }
            .scrollContentBackground(.hidden)
            .background(ThemeRadialBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCoinShopSheet = true
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
            .sheet(isPresented: $showCoinShopSheet) {
                CoinShopSheet()
            }
            .sheet(isPresented: $showMyAppsSheet, onDismiss: {
                myAppsSelection = SharedDefaults.loadMyAppsSelection()
            }) {
                MyAppsSheet()
            }
            .fullScreenCover(isPresented: $showAuthSheet) {
                AuthProvidersSheet()
            }
            .fullScreenCover(isPresented: $showAccountSheet) {
                AccountScreen()
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .essenceCatalog:
                    EssenceCatalogScreen()
                case .notificationSettings:
                    NotificationSettingsScreen()
                case .shieldSettings:
                    ShieldSettingsScreen()
                case .dailyPresetSettings:
                    DailyPresetSettingsScreen()
                case .lockButtonSettings:
                    LockButtonSettingsScreen()
                case .feedback:
                    FeedbackScreen(showSuccess: $showFeedbackSuccess)
                }
            }
            .onAppear {
                myAppsSelection = SharedDefaults.loadMyAppsSelection()
            }
            .onChange(of: limitSettings) { _, newValue in
                SharedDefaults.limitSettings = newValue
            }
            .alert("Error", isPresented: hasAuthError, presenting: authManager.error) { _ in
                Button("OK") { authManager.clearError() }
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert("Sent!", isPresented: $showFeedbackSuccess) {
                Button("OK") {}
            } message: {
                Text("Thank you for your feedback!")
            }
        }
    }

    // MARK: - Profile Row

    @ViewBuilder
    private var profileRow: some View {
        Button {
            if authManager.isAuthenticated {
                showAccountSheet = true
            } else {
                showAuthSheet = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(authManager.isAuthenticated ? .secondary : Color(.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.isAuthenticated ? displayName : "Guest")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    if authManager.isAuthenticated {
                        if let email = authManager.userEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Sign In / Sign Up")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var displayName: String {
        if let name = authManager.currentUser?.userMetadata["full_name"],
           case .string(let value) = name, !value.isEmpty {
            return value
        }
        return authManager.userEmail?.components(separatedBy: "@").first ?? String(localized: "User")
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
                Label("Syncing...", systemImage: "arrow.triangle.2.circlepath")
            } else if syncManager.lastError != nil {
                Label("Sync Failed", systemImage: "exclamationmark.icloud")
                    .foregroundStyle(.orange)
            } else {
                Label("Sync", systemImage: "checkmark.icloud")
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

}

// MARK: - Theme Picker

private struct ThemePicker<T: Hashable & Identifiable>: View {
    let themes: [T]
    @Binding var selected: T
    let label: KeyPath<T, String>
    let gradient: KeyPath<T, [Color]>
    let isPremium: KeyPath<T, Bool>

    @Environment(StoreManager.self) private var storeManager
    @State private var showPremiumSheet = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(themes) { theme in
                let isSelected = theme.id == selected.id
                let isLocked = theme[keyPath: isPremium] && !storeManager.isPremium
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
                        .opacity(isLocked ? 0.5 : 1.0)
                        .overlay {
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2.5)
                        )

                    Text(theme[keyPath: label])
                        .font(.caption)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                .onTapGesture {
                    if isLocked {
                        showPremiumSheet = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = theme
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet()
        }
    }
}

#Preview {
    ProfileScreen(navigationPath: .constant(NavigationPath()))
        .environment(EssenceCatalogManager.mock())
        .environment(AuthManager.mock())
        .environment(StoreManager.mock())
        .environment(SyncManager())
}
