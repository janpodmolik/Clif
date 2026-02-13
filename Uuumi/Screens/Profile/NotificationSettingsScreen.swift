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
            Section {
                Toggle("Notifikace", isOn: notifications.masterEnabled)
                    .tint(.blue)
            }

            // MARK: - Wind Alerts

            Section {
                SettingsRow(
                    title: "Upozornění na vítr",
                    description: "Oznámení při dosažení prahů větru.",
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
                    title: "Připomenutí vysokého větru",
                    description: "Po 30 minutách vysokého větru bez pauzy.",
                    isOn: notifications.windReminder,
                    disabled: disabled
                )
            }

            // MARK: - Breaks

            Section {
                SettingsRow(
                    title: "Konec committed breaku",
                    description: "Oznámení po vypršení naplánovaného breaku.",
                    isOn: notifications.breakCommittedEnded,
                    disabled: disabled
                )
            }

            Section {
                SettingsRow(
                    title: "Vítr na 0% během pauzy",
                    description: "Oznámení, když vítr klesne na 0% během pauzy.",
                    isOn: notifications.breakWindZero,
                    disabled: disabled
                )
            }

            // MARK: - Summaries

            // TODO: Implement daily summary scheduling (evening local notification with screen time stats)
            Section {
                SettingsRow(
                    title: "Denní souhrn",
                    description: "Večerní přehled screen time a stavu mazlíčka.",
                    isOn: notifications.dailySummary,
                    disabled: disabled
                )
            }

            // TODO: Implement evolution ready scheduling (morning notification if pet can evolve and hasn't yet)
            Section {
                SettingsRow(
                    title: "Evoluce připravena",
                    description: "Ranní oznámení, když mazlíček může evolvovat.",
                    isOn: notifications.evolutionReady,
                    disabled: disabled
                )
            }
        }
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
}
