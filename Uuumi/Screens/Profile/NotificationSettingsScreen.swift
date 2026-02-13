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
                NotificationToggleRow(
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
                    WindThresholdChips(notifications: notifications, disabled: disabled)
                }
            }

            Section {
                NotificationToggleRow(
                    title: "Připomenutí vysokého větru",
                    description: "Po 30 minutách vysokého větru bez pauzy.",
                    isOn: notifications.windReminder,
                    disabled: disabled
                )
            }

            // MARK: - Breaks

            Section {
                NotificationToggleRow(
                    title: "Konec committed breaku",
                    description: "Oznámení po vypršení naplánovaného breaku.",
                    isOn: notifications.breakCommittedEnded,
                    disabled: disabled
                )
            }

            Section {
                NotificationToggleRow(
                    title: "Vítr na 0% během pauzy",
                    description: "Oznámení, když vítr klesne na 0% během pauzy.",
                    isOn: notifications.breakWindZero,
                    disabled: disabled
                )
            }

            // MARK: - Summaries

            // TODO: Implement daily summary scheduling (evening local notification with screen time stats)
            Section {
                NotificationToggleRow(
                    title: "Denní souhrn",
                    description: "Večerní přehled screen time a stavu mazlíčka.",
                    isOn: notifications.dailySummary,
                    disabled: disabled
                )
            }

            // TODO: Implement evolution ready scheduling (morning notification if pet can evolve and hasn't yet)
            Section {
                NotificationToggleRow(
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

// MARK: - Wind Threshold Chips

private struct WindThresholdChips: View {
    @Binding var notifications: NotificationSettings
    let disabled: Bool

    var body: some View {
        HStack(spacing: 0) {
            chip("25%", isOn: $notifications.windLight)
            chip("60%", isOn: $notifications.windStrong)
            chip("85%", isOn: $notifications.windCritical)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }

    private func chip(_ label: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn.wrappedValue ? .primary : .tertiary)
                    .imageScale(.medium)
                Text(label)
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isOn.wrappedValue ? .primary : .tertiary)
            .background(isOn.wrappedValue ? Color(.tertiarySystemFill) : .clear)
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
}
