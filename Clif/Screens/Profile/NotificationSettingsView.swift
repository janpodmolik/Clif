import SwiftUI

struct NotificationSettingsView: View {
    @Binding var settings: LimitSettings

    var body: some View {
        Form {
            Section {
                ForEach(WindNotification.configurableNotifications, id: \.self) { notification in
                    Toggle(isOn: binding(for: notification)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(notification.title)
                                    .frame(width: 24)
                                Text(notification.settingsTitle)
                            }
                            Text(notification.settingsPreview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(notification.color)
                }
            } header: {
                Text("Upozornění při změně větru")
            } footer: {
                Text("Dostaneš notifikaci když vítr dosáhne vybrané úrovně.")
            }

            Section {
                Button("Zapnout všechny") {
                    settings.enabledNotifications = Set(WindNotification.configurableNotifications)
                }

                Button("Vypnout všechny") {
                    settings.enabledNotifications = []
                }
            }
        }
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for notification: WindNotification) -> Binding<Bool> {
        Binding(
            get: { settings.enabledNotifications.contains(notification) },
            set: { isEnabled in
                if isEnabled {
                    settings.enabledNotifications.insert(notification)
                } else {
                    settings.enabledNotifications.remove(notification)
                }
            }
        )
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView(settings: .constant(.default))
    }
}
