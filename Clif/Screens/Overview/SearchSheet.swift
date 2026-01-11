import SwiftUI

struct SearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Vyhledávání v historii")
                    .font(.title2.weight(.semibold))

                Text("Zde budeš moct vyhledávat mezi svými pety.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hledat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Hledat pety...")
        }
    }
}

#Preview {
    SearchSheet()
}
