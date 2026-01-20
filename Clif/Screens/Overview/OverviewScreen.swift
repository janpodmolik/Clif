import FamilyControls
import SwiftUI

struct OverviewScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager

    @State private var selectedActivePet: ActivePet?
    @State private var selectedArchivedDetail: ArchivedPetDetail?
    @State private var historyViewMode: HistoryViewMode = .list

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared

    enum HistoryViewMode {
        case list, grid
    }

    @State private var weeklyStats = WeeklyUsageStats.mock()

    private var completedPets: [ArchivedPetSummary] {
        archivedPetManager.completedPets
    }

    private var allSummaries: [ArchivedPetSummary] {
        archivedPetManager.summaries
    }

    private var activePets: [ActivePet] {
        petManager.activePets
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                    .padding(.horizontal, 20)

                PetScreenTimeCarousel(
                    activePets: activePets.compactMap { pet in
                        if case .daily(let daily) = pet { return daily }
                        return nil
                    },
                    fallbackStats: weeklyStats,
                    applicationTokens: screenTimeManager.activitySelection.applicationTokens,
                    categoryTokens: screenTimeManager.activitySelection.categoryTokens,
                    onPetTap: { pet in
                        selectedActivePet = .daily(pet)
                    }
                )

                HistoryIslandsCarousel(pets: completedPets) { summary in
                    Task {
                        selectedArchivedDetail = await archivedPetManager.loadDetail(for: summary)
                    }
                }
                .padding(.horizontal, 20)

                activeSection
                    .padding(.horizontal, 20)

                historySection
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(OverviewBackground())
        .onAppear {
            archivedPetManager.loadSummariesIfNeeded()
        }
        .fullScreenCover(item: $selectedActivePet) { pet in
            switch pet {
            case .daily(let daily):
                DailyPetDetailScreen(
                    pet: daily,
                    showOverviewActions: true,
                    onAction: { handleDailyAction($0, for: pet) }
                )
            case .dynamic(let dynamic):
                DynamicPetDetailScreen(
                    pet: dynamic,
                    showOverviewActions: true,
                    onAction: { handleDynamicAction($0, for: pet) }
                )
            }
        }
        .fullScreenCover(item: $selectedArchivedDetail) { detail in
            switch detail {
            case .daily(let pet):
                DailyPetArchivedDetailScreen(pet: pet)
            case .dynamic(let pet):
                DynamicPetArchivedDetailScreen(pet: pet)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Přehled")
                .font(.system(size: 32, weight: .bold))
            Text("Historie tvých petů a času u obrazovky.")
                .foregroundStyle(.secondary)
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aktuální")
                    .font(.headline)
                Spacer()
                Text("\(activePets.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if activePets.isEmpty {
                emptyActiveState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activePets) { pet in
                        switch pet {
                        case .daily(let daily):
                            ActivePetRow(pet: daily) {
                                selectedActivePet = pet
                            }
                        case .dynamic:
                            // TODO: Add row for DynamicPet
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    private var emptyActiveState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Žádní aktivní peti")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Vytvoř si nového peta na homepage.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Historie")
                    .font(.headline)
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        historyViewMode = historyViewMode == .list ? .grid : .list
                    }
                } label: {
                    Image(systemName: historyViewMode == .list ? "square.grid.2x2" : "list.bullet")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Text("\(allSummaries.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if allSummaries.isEmpty {
                emptyHistoryState
            } else {
                if historyViewMode == .list {
                    LazyVStack(spacing: 12) {
                        ForEach(allSummaries) { summary in
                            ArchivedPetRow(pet: summary) {
                                Task {
                                    selectedArchivedDetail = await archivedPetManager.loadDetail(for: summary)
                                }
                            }
                        }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(allSummaries) { summary in
                            ArchivedPetGridItem(pet: summary) {
                                Task {
                                    selectedArchivedDetail = await archivedPetManager.loadDetail(for: summary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyHistoryState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Zatím žádná historie")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Archivovaní peti se zobrazí zde.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private func handleDailyAction(_ action: DailyPetDetailAction, for pet: ActivePet) {
        switch action {
        case .showOnHomepage:
            selectedActivePet = nil
            if let url = URL(string: "clif://pet/\(pet.id.uuidString)") {
                UIApplication.shared.open(url)
            }
        case .blowAway, .replay, .delete, .limitedApps, .progress:
            break // TODO: Implement remaining actions
        }
    }

    private func handleDynamicAction(_ action: DynamicPetDetailAction, for pet: ActivePet) {
        switch action {
        case .showOnHomepage:
            selectedActivePet = nil
            if let url = URL(string: "clif://pet/\(pet.id.uuidString)") {
                UIApplication.shared.open(url)
            }
        case .blowAway, .replay, .delete, .limitedApps, .progress, .startBreak, .endBreak, .breakHistory:
            break // TODO: Implement remaining actions
        }
    }
}

private struct OverviewBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color.black.ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.08),
                        Color.blue.opacity(0.05),
                        Color(uiColor: .systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    OverviewScreen()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}
