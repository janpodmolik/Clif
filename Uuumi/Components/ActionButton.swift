import SwiftUI

/// Reusable action button with capsule background.
struct ActionButton: View {
    var icon: String?
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticType.impactMedium.trigger()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        ActionButton(icon: "trash", label: "Delete", color: .red) {}
        ActionButton(icon: "house.fill", label: "Show", color: .blue) {}
        ActionButton(label: "No icon", color: .green) {}
    }
    .padding()
}
#endif
