import SwiftUI

struct NotificationToggleRow: View {
    let title: String
    var description: String? = nil
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body.weight(.semibold))

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(.blue)
        .padding(.vertical, 8)
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }
}
