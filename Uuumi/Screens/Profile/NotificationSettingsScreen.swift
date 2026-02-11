import SwiftUI

struct NotificationSettingsScreen: View {
    @State private var limitSettings = SharedDefaults.limitSettings

    private var notifications: Binding<NotificationSettings> {
        $limitSettings.notifications
    }

    private var disabled: Bool {
        !limitSettings.notifications.masterEnabled
    }

    var body: some View {
        Form {
            // MARK: - Master Toggle
            Section {
                Toggle("Notifikace", isOn: notifications.masterEnabled)
                    .tint(.blue)
            }

            // MARK: - Wind
            Section(header: sectionHeader("Vítr")) {
                NotificationToggleRow(
                    title: WindNotification.light.settingsTitle,
                    isOn: notifications.windLight,
                    disabled: disabled
                )

                NotificationToggleRow(
                    title: WindNotification.strong.settingsTitle,
                    isOn: notifications.windStrong,
                    disabled: disabled
                )

                NotificationToggleRow(
                    title: WindNotification.critical.settingsTitle,
                    isOn: notifications.windCritical,
                    disabled: disabled
                )

                NotificationToggleRow(
                    title: "Připomenutí vysokého větru",
                    description: "Upozornění po 30 minutách vysokého větru bez aktivní pauzy.",
                    isOn: notifications.windReminder,
                    disabled: disabled
                )
            }
            .headerProminence(.increased)

            // MARK: - Breaks
            Section(header: sectionHeader("Pauzy")) {
                NotificationToggleRow(
                    title: "Konec committed breaku",
                    description: "Oznámení po vypršení naplánovaného breaku.",
                    isOn: notifications.breakCommittedEnded,
                    disabled: disabled
                )

                NotificationToggleRow(
                    title: "Vítr na 0%",
                    description: "Oznámení, když vítr klesne na 0% během pauzy.",
                    isOn: notifications.breakWindZero,
                    disabled: disabled
                )
            }
            .headerProminence(.increased)

            // MARK: - Summaries & Reminders
            Section(header: sectionHeader("Ostatní")) {
                // TODO: Implement daily summary scheduling (evening local notification with screen time stats)
                NotificationToggleRow(
                    title: "Denní souhrn",
                    description: "Večerní přehled screen time a stavu mazlíčka.",
                    isOn: notifications.dailySummary,
                    disabled: disabled
                )

                // TODO: Implement evolution ready scheduling (morning notification if pet can evolve and hasn't yet)
                NotificationToggleRow(
                    title: "Evoluce připravena",
                    description: "Ranní oznámení, když mazlíček může evolvovat.",
                    isOn: notifications.evolutionReady,
                    disabled: disabled
                )
            }
            .headerProminence(.increased)
        }
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
    }
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .textCase(nil)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
}
