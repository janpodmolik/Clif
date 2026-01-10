import SwiftUI

struct EssenceOriginBadge: View {
    let essence: Essence

    var body: some View {
        HStack(spacing: 12) {
            Image(essence.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Origin")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Started with \(essence.displayName)")
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview {
    VStack {
        EssenceOriginBadge(essence: .plant)
    }
    .padding()
}
#endif
