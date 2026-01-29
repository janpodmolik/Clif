import SwiftUI

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    @State private var limitSettings = SharedDefaults.limitSettings

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Notifications & Shield
                Section {
                    NavigationLink {
                        NotificationSettingsView(settings: $limitSettings)
                    } label: {
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
    ProfileScreen()
        .environment(PetManager.mock())
}
