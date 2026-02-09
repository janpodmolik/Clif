import SwiftUI

struct PremiumSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)

                Text("Uuumi Premium")
                    .font(.title.weight(.bold))

                Text("Odemkni plný potenciál svých petů.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "sparkles", text: "Exkluzivní evoluce")
                    featureRow(icon: "paintpalette.fill", text: "Speciální témata")
                    featureRow(icon: "chart.bar.fill", text: "Detailní statistiky")
                    featureRow(icon: "infinity", text: "Neomezený počet petů")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        // TODO: Purchase premium
                    } label: {
                        Text("Získat Premium")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.yellow)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        // TODO: Open coin shop
                    } label: {
                        Label("Koupit Coins", systemImage: "u.circle.fill")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    PremiumSheet()
}
