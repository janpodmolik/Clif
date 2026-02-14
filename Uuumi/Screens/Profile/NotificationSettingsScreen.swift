import SwiftUI

struct NotificationSettingsScreen: View {
    @Environment(PetManager.self) private var petManager
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

            Section {
                SettingsRow(
                    title: "Evoluce připravena",
                    description: "Oznámení, když Uuumi může evolvovat.",
                    isOn: notifications.evolutionReady,
                    disabled: disabled
                )
            }

            Section {
                SettingsRow(
                    title: "Denní souhrn",
                    description: "Přehled screen time a stavu Uuumi.",
                    isOn: notifications.dailySummary,
                    disabled: disabled
                )

                if limitSettings.notifications.dailySummary {
                    DatePicker(
                        "Čas",
                        selection: dailySummaryTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(disabled)
                }
            }
        }
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue

            ScheduledNotificationManager.refresh(
                isEvolutionAvailable: petManager.currentPet?.isEvolutionAvailable ?? false,
                hasPet: petManager.hasPet,
                nextEvolutionUnlockDate: petManager.currentPet?.evolutionHistory.nextEvolutionUnlockDate
            )
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
