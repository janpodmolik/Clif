import SwiftUI

enum ProfileDestination: Hashable {
    case notifications
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
                // MARK: - Notifications & Shield
                Section {
                    NavigationLink(value: ProfileDestination.notifications) {
                        HStack {
                            Label("Notifikace", systemImage: "bell.fill")
                            Spacer()
                            Text("\(limitSettings.enabledNotifications.count) aktivních")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $limitSettings.dayStartShieldEnabled) {
                        Label("Denní shield", systemImage: "calendar")
                    }
                    .tint(.blue)
                } header: {
                    Text("Upozornění")
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
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .notifications:
                    NotificationSettingsView(settings: $limitSettings)
                case .essenceCatalog:
                    EssenceCatalogScreen()
                }
            }
            .onChange(of: limitSettings) { _, newValue in
                SharedDefaults.limitSettings = newValue
            }
        }
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
