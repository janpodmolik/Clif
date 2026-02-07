import SwiftUI

enum ProfileDestination: Hashable {
    case essenceCatalog
}

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .automatic
    @AppStorage("selectedDayTheme") private var dayTheme: DayTheme = .morningHaze
    @AppStorage("selectedNightTheme") private var nightTheme: NightTheme = .deepNight
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var showPremiumSheet = false
    @Binding var navigationPath: NavigationPath

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                // MARK: - Notifications
                Section {
                    Picker(selection: $limitSettings.notificationMode) {
                        ForEach(NotificationMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    } label: {
                        Label("Notifikace", systemImage: "bell.fill")
                    }
                } header: {
                    Text("Upozornění")
                } footer: {
                    Text(limitSettings.notificationMode.description)
                }

                // MARK: - Day Start Shield
                Section {
                    Toggle(isOn: $limitSettings.dayStartShieldEnabled) {
                        Label("Denní shield", systemImage: "calendar")
                    }
                    .tint(.blue)
                } footer: {
                    Text("Denní shield ti umožní vybrat si náročnost dne před prvním použitím blokovaných aplikací.")
                }

                // MARK: - Essence Catalog
                Section(header: Text("Kolekce")) {
                    NavigationLink(value: ProfileDestination.essenceCatalog) {
                        HStack {
                            Label("Katalog Essencí", systemImage: "sparkles")
                            Spacer()
                            Text("\(catalogManager.unlockedEssences.count)/\(Essence.allCases.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Appearance
                Section {
                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    } label: {
                        Label("Režim", systemImage: "paintbrush.fill")
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
                } header: {
                    Text("Vzhled")
                } footer: {
                    if appearanceMode == .automatic {
                        Text("Pozadí se mění automaticky podle denní doby.")
                    }
                }

                // MARK: - About
                Section(header: Text("O aplikaci")) {
                    HStack {
                        Label("Verze", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "mailto:support@clifapp.com")!) {
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
            .safeAreaPadding(.bottom, 80)
            .navigationTitle("Profil")
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
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .essenceCatalog:
                    EssenceCatalogScreen()
                }
            }
            .onChange(of: limitSettings) { _, newValue in
                SharedDefaults.limitSettings = newValue
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
}
