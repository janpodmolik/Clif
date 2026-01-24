import SwiftUI

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    @State private var limitSettings = SharedDefaults.limitSettings

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Limits & Notifications
                Section {
                    NavigationLink {
                        ShieldSettingsView(settings: $limitSettings)
                    } label: {
                        HStack {
                            Label("Aktivace shieldu", systemImage: "shield.fill")
                            Spacer()
                            Text(shieldLevelDescription)
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        NotificationSettingsView(settings: $limitSettings)
                    } label: {
                        HStack {
                            Label("Notifikace", systemImage: "bell.fill")
                            Spacer()
                            Text("\(limitSettings.notificationLevels.count) aktivních")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $limitSettings.morningShieldEnabled) {
                        Label("Ranní shield", systemImage: "sun.horizon.fill")
                    }
                    .tint(.blue)
                } header: {
                    Text("Limity a upozornění")
                } footer: {
                    Text("Ranní shield ti umožní vybrat si náročnost dne před prvním použitím blokovaných aplikací.")
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

                    Button("Reset Morning Shield") {
                        SharedDefaults.isMorningShieldActive = true
                        SharedDefaults.windPresetLockedForToday = false
                    }

                    Button("Simulate Day Reset") {
                        SharedDefaults.monitoredWindPoints = 0
                        SharedDefaults.monitoredLastThresholdSeconds = 0
                        SharedDefaults.lastKnownWindLevel = 0
                        SharedDefaults.windPresetLockedForToday = false
                        SharedDefaults.isMorningShieldActive = limitSettings.morningShieldEnabled
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

    private var shieldLevelDescription: String {
        guard let level = limitSettings.shieldActivationLevel else {
            return "Vypnuto"
        }
        return level.label
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
