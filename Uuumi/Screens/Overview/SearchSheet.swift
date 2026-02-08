import SwiftUI

struct SearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ArchivedPetManager.self) private var archivedPetManager

    @State private var filter: PetSearchFilter
    @State private var selectedArchivedPet: ArchivedPet?
    @State private var activeFilterSheet: FilterType?

    init(initialFilter: PetSearchFilter = PetSearchFilter()) {
        _filter = State(initialValue: initialFilter)
    }

    private enum FilterType: Identifiable {
        case status
        case date
        case duration
        case essence

        var id: Self { self }
    }

    private var archivedPets: [ArchivedPetSummary] {
        archivedPetManager.summaries
    }

    private var filteredPets: [ArchivedPetSummary] {
        archivedPets.filter { pet in
            // Text search (name + purpose)
            if !filter.searchText.isEmpty {
                let searchLower = filter.searchText.lowercased()
                let nameMatch = pet.name.lowercased().contains(searchLower)
                let purposeMatch = pet.purpose?.lowercased().contains(searchLower) ?? false
                if !nameMatch && !purposeMatch {
                    return false
                }
            }

            // Date range filter
            if let interval = filter.dateRange.dateInterval(
                customStart: filter.customStartDate,
                customEnd: filter.customEndDate
            ) {
                if !interval.contains(pet.archivedAt) {
                    return false
                }
            }

            // Status filter
            if let reason = filter.statusFilter.matchingReason,
               pet.archiveReason != reason {
                return false
            }

            // Essence filter
            if let essence = pet.essence, !filter.essenceFilter.contains(essence) {
                return false
            }

            // Duration filter
            if !filter.matchesDuration(days: pet.totalDays) {
                return false
            }

            return true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredPets.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hledat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if filter.hasActiveFilters {
                        Button("Reset") {
                            withAnimation {
                                filter.reset()
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                filterPillsBar
            }
            .searchable(text: $filter.searchText, prompt: "Hledat pety...")
        }
        .tint(.primary)
        .sheet(item: $activeFilterSheet) { type in
            filterSheet(for: type)
        }
        .fullScreenCover(item: $selectedArchivedPet) { pet in
            ArchivedPetDetailScreen(pet: pet)
        }
    }

    // MARK: - Subviews

    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(
                    label: filter.statusFilter == .all ? "Stav" : filter.statusFilter.rawValue,
                    isActive: filter.statusFilter != .all
                ) {
                    activeFilterSheet = .status
                }

                FilterPill(
                    label: filter.dateRange == .all ? "Období" : filter.dateRange.rawValue,
                    isActive: filter.dateRange != .all
                ) {
                    activeFilterSheet = .date
                }

                FilterPill(
                    label: filter.isDurationFiltered ? filter.durationLabel : "Délka",
                    isActive: filter.isDurationFiltered
                ) {
                    activeFilterSheet = .duration
                }

                FilterPill(
                    label: filter.essenceFilter == Set(Essence.allCases) ? "Essence" : "\(filter.essenceFilter.count) essence",
                    isActive: filter.essenceFilter != Set(Essence.allCases)
                ) {
                    activeFilterSheet = .essence
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack {
                    Text("\(filteredPets.count) výsledků")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 4)

                ForEach(filteredPets) { summary in
                    ArchivedPetRow(pet: summary) {
                        Task {
                            selectedArchivedPet = await archivedPetManager.loadDetail(for: summary)
                        }
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func filterSheet(for type: FilterType) -> some View {
        switch type {
        case .status:
            StatusFilterSheet(selection: $filter.statusFilter)
        case .date:
            DateFilterSheet(
                dateRange: $filter.dateRange,
                customStart: $filter.customStartDate,
                customEnd: $filter.customEndDate
            )
        case .duration:
            DurationFilterSheet(
                minDuration: $filter.minDuration,
                maxDuration: $filter.maxDuration
            )
        case .essence:
            EssenceFilterSheet(selection: $filter.essenceFilter)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            if filter.hasActiveFilters || !filter.searchText.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Žádné výsledky")
                    .font(.title2.weight(.semibold))

                Text("Zkus změnit vyhledávání nebo filtry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Vymazat filtry") {
                    withAnimation {
                        filter.reset()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Vyhledávání v historii")
                    .font(.title2.weight(.semibold))

                Text("Zadej jméno peta nebo použij filtry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isActive ? Color.primary.opacity(0.1) : Color.clear)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.primary.opacity(isActive ? 0.5 : 0.3), lineWidth: 1)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchSheet()
        .environment(ArchivedPetManager.mock())
}
