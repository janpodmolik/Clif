import SwiftUI

struct ShieldSettingsView: View {
    @Binding var settings: LimitSettings

    var body: some View {
        Form {
            Section {
                ForEach(shieldOptions, id: \.level) { option in
                    Button {
                        settings.shieldActivationLevel = option.level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .foregroundStyle(.primary)
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if settings.shieldActivationLevel == option.level {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("Kdy aktivovat shield")
            } footer: {
                Text("Shield zablokuje přístup k limitovaným aplikacím. Čím nižší úroveň, tím dříve se shield aktivuje.")
            }

            Section {
                Button(role: .destructive) {
                    settings.shieldActivationLevel = nil
                } label: {
                    HStack {
                        Text("Vypnout automatický shield")
                        Spacer()
                        if settings.shieldActivationLevel == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } footer: {
                Text("Tvůj mazlíček bude odfouknut při dosažení 100% bez předchozího varování.")
            }
        }
        .navigationTitle("Aktivace shieldu")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var shieldOptions: [ShieldOption] {
        [
            ShieldOption(
                level: .low,
                title: "Mírný vítr (5%)",
                description: "Shield se aktivuje brzy, jakmile vítr začne foukat"
            ),
            ShieldOption(
                level: .medium,
                title: "Střední vítr (50%)",
                description: "Shield se aktivuje v polovině limitu"
            ),
            ShieldOption(
                level: .high,
                title: "Silný vítr (80%)",
                description: "Shield se aktivuje až při vysokém větru"
            )
        ]
    }
}

private struct ShieldOption {
    let level: WindLevel
    let title: String
    let description: String
}

#Preview {
    NavigationView {
        ShieldSettingsView(settings: .constant(.default))
    }
}
