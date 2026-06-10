import SwiftUI

struct ShieldSettingsScreen: View {
    @Environment(AnalyticsManager.self) private var analytics
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var notificationsAuthorized = SharedDefaults.notificationsAuthorized
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            // MARK: - Notifications Warning

            if !notificationsAuthorized {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications are off", systemImage: "bell.slash.fill")
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        Text("Unlocking a shield works through a notification. Without it, tapping Unlock closes the shield but nothing guides you back to Uuumi.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Enable in Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }
            }

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
        .task { await refreshNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await refreshNotificationStatus() }
            }
        }
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

    private func refreshNotificationStatus() async {
        await AppDelegate.cacheNotificationAuthStatus()
        notificationsAuthorized = SharedDefaults.notificationsAuthorized
    }
}

#Preview {
    NavigationStack {
        ShieldSettingsScreen()
    }
}
