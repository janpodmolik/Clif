import SwiftUI

struct ComingSoonGridItem: View {
    let name: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "questionmark")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 64, height: 64)

            VStack(spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Již brzy")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { _ in
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
        spacing: 12
    ) {
        ComingSoonGridItem(name: "Crystal")
        ComingSoonGridItem(name: "Flame")
        ComingSoonGridItem(name: "Water")
    }
    .padding()
}
