import SwiftUI

enum ProfileDestination: Hashable {
    case essenceCatalog
}

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
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
                Section(header: Text("Vzhled")) {
                    Toggle(isOn: $isDarkModeEnabled) {
                        Label("Tmavý režim", systemImage: "moon.fill")
                    }
                    .tint(.purple)
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

#Preview {
    ProfileScreen(navigationPath: .constant(NavigationPath()))
        .environment(PetManager.mock())
        .environment(EssenceCatalogManager.mock())
}
