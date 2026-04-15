import SwiftUI
import UserNotifications

struct NotificationSettingsScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.scenePhase) private var scenePhase
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var systemNotificationsEnabled: Bool {
        authorizationStatus == .authorized
    }

    private var notifications: Binding<NotificationSettings> {
        $limitSettings.notifications
    }

    private var disabled: Bool {
        !systemNotificationsEnabled || !limitSettings.notifications.masterEnabled
    }

    var body: some View {
        Form {
            if authorizationStatus == .notDetermined {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Notifications are not enabled")
                                .font(AppFont.quicksand(.subheadline, weight: .semiBold))
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.blue)
                        }

                        Text("Allow notifications so Uuumi can reach you when it matters.")
                            .font(AppFont.quicksand(.caption, weight: .medium))
                            .foregroundStyle(.secondary)

                        Button("Enable Notifications") {
                            Task {
                                await AppDelegate.requestNotificationPermission()
                                await checkNotificationStatus()
                            }
                        }
                        .font(AppFont.quicksand(.subheadline, weight: .semiBold))
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            } else if !systemNotificationsEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Notifications are disabled in system settings")
                                .font(AppFont.quicksand(.subheadline, weight: .semiBold))
                        } icon: {
                            Image(systemName: "bell.slash.fill")
                                .foregroundStyle(.orange)
                        }

                        Text("Enable them in Settings to receive notifications.")
                            .font(AppFont.quicksand(.caption, weight: .medium))
                            .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(AppFont.quicksand(.subheadline, weight: .semiBold))
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Toggle("Notifications", isOn: notifications.masterEnabled)
                    .tint(.blue)
                    .disabled(!systemNotificationsEnabled)
                    .opacity(!systemNotificationsEnabled ? 0.4 : 1.0)
            }

            // MARK: - Wind Alerts

            Section {
                SettingsRow(
                    title: "Wind Alerts",
                    description: "Notifications when wind thresholds are reached.",
                    isOn: Binding(
                        get: { limitSettings.notifications.anyWindEnabled },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                limitSettings.notifications.windLight = newValue
                                limitSettings.notifications.windStrong = newValue
                                limitSettings.notifications.windCritical = newValue
                            }
                        }
                    ),
                    disabled: disabled
                )

                if limitSettings.notifications.anyWindEnabled {
                    MultiChipPicker(
                        options: [
                            ("25 %", notifications.windLight),
                            ("60 %", notifications.windStrong),
                            ("85 %", notifications.windCritical),
                        ],
                        disabled: disabled
                    )
                }
            }

            Section {
                SettingsRow(
                    title: "High Wind Reminder",
                    description: "After 5 minutes of wind without a break.",
                    isOn: notifications.windReminder,
                    disabled: disabled
                )
            }

            // MARK: - Breaks

            Section {
                SettingsRow(
                    title: "Committed Break Ended",
                    description: "Notification when a scheduled break expires.",
                    isOn: notifications.breakCommittedEnded,
                    disabled: disabled
                )
            }

            Section {
                SettingsRow(
                    title: "Wind at 0% During Break",
                    description: "Notification when wind drops to 0% during a break.",
                    isOn: notifications.breakWindZero,
                    disabled: disabled
                )
            }

            // MARK: - Summaries

            Section {
                SettingsRow(
                    title: "Evolution Ready",
                    description: "Notification when Uuumi can evolve.",
                    isOn: notifications.evolutionReady,
                    disabled: disabled
                )
            }

            Section {
                SettingsRow(
                    title: "Daily Summary",
                    description: "Overview of screen time and Uuumi's status.",
                    isOn: notifications.dailySummary,
                    disabled: disabled
                )

                if limitSettings.notifications.dailySummary {
                    DatePicker(
                        "Time",
                        selection: dailySummaryTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(disabled)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            limitSettings = SharedDefaults.limitSettings
        }
        .task { await checkNotificationStatus() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await checkNotificationStatus() }
            }
        }
        .onChange(of: limitSettings) { oldValue, newValue in
            SharedDefaults.limitSettings = newValue

            if oldValue.notifications.masterEnabled != newValue.notifications.masterEnabled {
                analytics.send(.configChanged(key: "notifications_master", value: "\(newValue.notifications.masterEnabled)"))
            }

            ScheduledNotificationManager.refresh(
                isEvolutionAvailable: petManager.currentPet?.isEvolutionAvailable ?? false,
                hasPet: petManager.hasPet,
                nextEvolutionUnlockDate: petManager.currentPet?.evolutionHistory.nextEvolutionUnlockDate
            )
        }
    }

    // MARK: - Notification Status

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if authorizationStatus != settings.authorizationStatus {
            authorizationStatus = settings.authorizationStatus
        }
    }

    // MARK: - Time Bindings

    private var dailySummaryTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(
                    hour: limitSettings.notifications.dailySummaryHour,
                    minute: limitSettings.notifications.dailySummaryMinute
                )) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                limitSettings.notifications.dailySummaryHour = components.hour ?? 20
                limitSettings.notifications.dailySummaryMinute = components.minute ?? 0
            }
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
    .environment(PetManager.mock())
}
