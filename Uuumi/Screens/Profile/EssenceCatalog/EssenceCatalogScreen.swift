import SwiftUI

struct EssenceCatalogScreen: View {
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(PetManager.self) private var petManager

    @State private var selectedEssenceRecord: EssenceRecord?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                essenceGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .navigationTitle("Essence Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEssenceRecord) { record in
            EssenceDetailSheet(
                record: record,
                summaries: archivedPetManager.summaries
            )
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Unlock new evolution paths for your pets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(catalogManager.allUnlocked.count)/\(Essence.allCases.count) unlocked")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var essenceGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(catalogManager.catalogEntries) { entry in
                let record = essenceRecord(for: entry.essence)
                EssenceCatalogGridItem(
                    entry: entry,
                    essenceRecord: record
                )
                .onTapGesture {
                    guard entry.isUnlocked else { return }
                    selectedEssenceRecord = record ?? EssenceRecord(
                        id: entry.essence.rawValue,
                        essence: entry.essence,
                        bestPhase: nil,
                        petCount: 0
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func essenceRecord(for essence: Essence) -> EssenceRecord? {
        archivedPetManager.essenceRecords(currentPet: petManager.currentPet)
            .first { $0.essence == essence }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EssenceCatalogScreen()
    }
    .environment(EssenceCatalogManager.mock())
    .environment(ArchivedPetManager())
    .environment(PetManager.mock())
}
