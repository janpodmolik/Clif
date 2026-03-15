import SwiftUI

struct ShieldSettingsScreen: View {
    @State private var limitSettings = SharedDefaults.limitSettings

    var body: some View {
        Form {
            // MARK: - Safety Shield

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spustit safety shield při")
                        .fontWeight(.bold)
                    Text("Automatická ochrana při dosažení procenta větru.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                ChipPicker(
                    options: [80, 100],
                    selection: $limitSettings.safetyShieldActivationThreshold,
                    label: { "\($0) %" }
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bezpečné odemknutí pod")
                        .fontWeight(.bold)
                    Text("Vítr musí klesnout pod zvolený práh pro odemknutí bez postihu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                ChipPicker(
                    options: [0, 50, 80],
                    selection: $limitSettings.safetyUnlockThreshold,
                    label: { "\($0) %" }
                )
            }

            // MARK: - Po breaku

            Section {
                SettingsRow(
                    title: "Auto-lock po committed breaku",
                    description: "Zapne free break po dokončení committed breaku.",
                    isOn: $limitSettings.autoLockAfterCommittedBreak
                )
            }
        }
        .navigationTitle("Shield")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
    }
}

#Preview {
    NavigationStack {
        ShieldSettingsScreen()
    }
}
