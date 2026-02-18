import SwiftUI

struct NoEssenceCard: View {
    @State private var showEssenceCatalog = false

    var body: some View {
        HStack(spacing: 16) {
            PetImage(Blob.shared)
                .padding(8)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Zatím bez esence")
                    .font(.headline)

                Text("Podívej se na dostupné esence v katalogu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
        .glassCard()
        .onTapGesture {
            showEssenceCatalog = true
        }
        .sheet(isPresented: $showEssenceCatalog) {
            NavigationStack {
                EssenceCatalogScreen()
                    .dismissButton { showEssenceCatalog = false }
            }
            .presentationDetents([.large])
        }
    }
}

#if DEBUG
#Preview {
    NoEssenceCard()
        .padding()
}
#endif
