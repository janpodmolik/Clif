import SwiftUI

struct DynamicPetArchivedDetailScreen: View {
    let pet: ArchivedDynamicPet

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("TODO: Implement")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    DynamicPetArchivedDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}
