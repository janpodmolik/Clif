import SwiftUI

struct ProfileScreen: View {
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                        .tint(.green)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileScreen()
}
