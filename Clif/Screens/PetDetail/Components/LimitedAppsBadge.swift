import SwiftUI

struct LimitedAppsBadge: View {
    let appCount: Int
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "app.badge.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Limited Apps")
                        .font(.subheadline.weight(.medium))

                    Text("\(appCount) apps monitored")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .glassCard()
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        LimitedAppsBadge(appCount: 12, onTap: {})
        LimitedAppsBadge(appCount: 5)
    }
    .padding()
}
#endif
