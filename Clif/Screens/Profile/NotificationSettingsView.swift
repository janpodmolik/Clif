import SwiftUI

struct NotificationSettingsView: View {
    @Binding var settings: LimitSettings

    var body: some View {
        Form {
            Section {
                ForEach(notificationOptions, id: \.level) { option in
                    Toggle(isOn: binding(for: option.level)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(option.color)
                                    .frame(width: 24)
                                Text(option.title)
                            }
                            Text(option.preview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(option.color)
                }
            } header: {
                Text("Upozornění při změně větru")
            } footer: {
                Text("Dostaneš notifikaci když vítr přejde do vybrané úrovně.")
            }

            Section {
                Button("Zapnout všechny") {
                    settings.notificationLevels = [.low, .medium, .high]
                }

                Button("Vypnout všechny") {
                    settings.notificationLevels = []
                }
            }
        }
        .navigationTitle("Notifikace")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for level: WindLevel) -> Binding<Bool> {
        Binding(
            get: { settings.notificationLevels.contains(level) },
            set: { isEnabled in
                if isEnabled {
                    settings.notificationLevels.insert(level)
                } else {
                    settings.notificationLevels.remove(level)
                }
            }
        )
    }

    private var notificationOptions: [NotificationOption] {
        [
            NotificationOption(
                level: .low,
                title: "Mírný vítr (5%)",
                preview: "\"Vítr se zvedá\" - mírné varování",
                icon: "wind",
                color: .green
            ),
            NotificationOption(
                level: .medium,
                title: "Střední vítr (50%)",
                preview: "\"Silnější vítr!\" - výrazné varování",
                icon: "wind",
                color: .orange
            ),
            NotificationOption(
                level: .high,
                title: "Silný vítr (80%)",
                preview: "\"Nebezpečný vítr!\" - poslední varování",
                icon: "wind",
                color: .red
            )
        ]
    }
}

private struct NotificationOption {
    let level: WindLevel
    let title: String
    let preview: String
    let icon: String
    let color: Color
}

#Preview {
    NavigationView {
        NotificationSettingsView(settings: .constant(.default))
    }
}
