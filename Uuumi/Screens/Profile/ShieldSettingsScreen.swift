import SwiftUI

struct ShieldSettingsScreen: View {
    @State private var limitSettings = SharedDefaults.limitSettings

    var body: some View {
        Form {
            // MARK: - Safety Shield

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activate Safety Shield at")
                        .fontWeight(.bold)
                    Text("Automatic protection when the wind percentage is reached.")
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
                    Text("Safe Unlock Below")
                        .fontWeight(.bold)
                    Text("Wind must drop below the selected threshold to unlock without penalty.")
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
                    title: "Auto-lock After Committed Break",
                    description: "Enables free break after completing a committed break.",
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
