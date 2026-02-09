import SwiftUI

struct EssenceDetailSheet: View {
    let record: EssenceRecord
    let summaries: [ArchivedPetSummary]

    @Environment(\.dismiss) private var dismiss
    @State private var showSearch = false

    private var path: EvolutionPath { record.evolutionPath }
    private var color: Color { path.themeColor }

    private var matchingSummaries: [ArchivedPetSummary] {
        summaries.filter { $0.essence == record.essence }
    }

    private var completedCount: Int {
        matchingSummaries.filter { $0.archiveReason == .completed }.count
    }

    private var blownCount: Int {
        matchingSummaries.filter { $0.archiveReason == .blown }.count
    }

    /// Mock pet for showcase evolution carousel.
    private var showcasePet: ArchivedPet {
        .mock(
            phase: record.bestPhase ?? 1,
            archiveReason: .completed,
            totalDays: 14
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    evolutionSection
                    statsRow
                    showPetsButton
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(path.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
        }
        .tint(.primary)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showSearch) {
            SearchSheet(initialFilter: PetSearchFilter(essenceFilter: [record.essence]))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(record.essence.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text(record.essence.rarity.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(record.essence.rarity.color)

            Text(record.essence.catalogDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Evolution Carousel

    private var evolutionSection: some View {
        EvolutionCarousel(
            pet: showcasePet,
            showCurrentBadge: false,
            showBlobStatusBadge: false
        )
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(record.petCount)", label: "Petů")
            divider
            statItem(value: "\(record.bestPhase ?? 0)/\(path.maxPhases)", label: "Best Phase")
            divider
            statItem(value: "\(completedCount)", label: "Dokončeno")
            divider
            statItem(value: "\(blownCount)", label: "Odfouknutí")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 1, height: 28)
    }

    // MARK: - Show Pets Button

    private var showPetsButton: some View {
        Button {
            showSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Zobrazit pety")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EssenceDetailSheet(
                record: EssenceRecord(id: "plant", essence: .plant, bestPhase: 3, petCount: 5),
                summaries: ArchivedPetSummary.mockList()
            )
        }
}
