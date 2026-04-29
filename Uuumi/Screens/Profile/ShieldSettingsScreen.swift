import SwiftUI

struct ShieldSettingsScreen: View {
    @Environment(AnalyticsManager.self) private var analytics
    @State private var limitSettings = SharedDefaults.limitSettings

    var body: some View {
        Form {
            // MARK: - Safety Shield

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save your pet automatically")
                        .fontWeight(.bold)
                    Text("Locks apps when wind reaches the chosen level.")
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
        .onChange(of: limitSettings) { oldValue, newValue in
            SharedDefaults.limitSettings = newValue

            if oldValue.safetyShieldActivationThreshold != newValue.safetyShieldActivationThreshold {
                analytics.send(.configChanged(key: "safety_shield_activation", value: "\(newValue.safetyShieldActivationThreshold)"))
            }
            if oldValue.safetyUnlockThreshold != newValue.safetyUnlockThreshold {
                analytics.send(.configChanged(key: "safety_unlock_threshold", value: "\(newValue.safetyUnlockThreshold)"))
            }
            if oldValue.autoLockAfterCommittedBreak != newValue.autoLockAfterCommittedBreak {
                analytics.send(.configChanged(key: "auto_lock_after_committed", value: "\(newValue.autoLockAfterCommittedBreak)"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShieldSettingsScreen()
    }
}
