import SwiftUI

struct NoEssenceCard: View {
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(Blob.shared.assetName(for: .happy))
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Zatím bez esence")
                    .font(.headline)

                Text("Najdi esenci ve svém inventáři")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard()
        .onTapGesture {
            onTap()
        }
    }
}

#if DEBUG
#Preview {
    NoEssenceCard {
        print("Open inventory")
    }
    .padding()
}
#endif
