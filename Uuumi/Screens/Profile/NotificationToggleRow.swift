import SwiftUI

struct NotificationToggleRow: View {
    let title: String
    var description: String? = nil
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(title, isOn: $isOn)
                .tint(.blue)

            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }
}
