import SwiftUI

struct SettingsRow: View {
    let title: String
    var description: String? = nil
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .fontWeight(.bold)
            if let description {
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.blue)
        .toggleStyle(.settingsRow)
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Top-Aligned Toggle Style

private struct SettingsRowToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                configuration.label
            }
            Spacer(minLength: 8)
            Toggle("", isOn: configuration.$isOn)
                .labelsHidden()
                .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}

extension ToggleStyle where Self == SettingsRowToggleStyle {
    static var settingsRow: SettingsRowToggleStyle { .init() }
}
