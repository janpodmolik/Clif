import SwiftUI

struct ProfileScreen: View {
    @Environment(PetManager.self) private var petManager
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                        .tint(.green)
                }

                #if DEBUG
                Section(header: Text("Debug")) {
                    Button("Delete All Active Pets", role: .destructive) {
                        deleteAllActivePets()
                    }
                    .disabled(petManager.activePets.isEmpty)
                }
                #endif
            }
            .navigationTitle("Profile")
        }
    }

    #if DEBUG
    private func deleteAllActivePets() {
        for pet in petManager.activePets {
            petManager.delete(id: pet.id)
        }
    }
    #endif
}

#Preview {
    ProfileScreen()
        .environment(PetManager.mock())
}
