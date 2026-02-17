import SwiftUI

/// Full-width capsule button: black background + white text in light mode,
/// white background + black text in dark mode. Adapts automatically.
///
/// Usage:
/// ```swift
/// Button("Continue") { }
///     .buttonStyle(.primary)
/// ```
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(isEnabled ? Color(.systemBackground) : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? Color(.label) : Color(.tertiarySystemFill), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        Button("Enabled Button") {}
            .buttonStyle(.primary)

        Button("Disabled Button") {}
            .buttonStyle(.primary)
            .disabled(true)
    }
    .padding()
}
#endif
