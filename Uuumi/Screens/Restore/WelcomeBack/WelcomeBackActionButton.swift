import SwiftUI

/// Reusable chevron-style action button used across WelcomeBack phases.
struct WelcomeBackActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color?
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor ?? .primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(iconColor ?? .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
