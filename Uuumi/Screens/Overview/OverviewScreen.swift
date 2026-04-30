import SwiftUI
import Combine

struct OverviewScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager

    @State private var selectedActivePet: Pet?
    @State private var selectedArchivedPet: ArchivedPet?
    @State private var selectedEssenceRecord: EssenceRecord?
    @State private var showSearch = false
    @State private var historyViewMode: HistoryViewMode = .list
    @State private var refreshTick: Int = 0
    @State private var hourlyAggregate: HourlyAggregate?
    @State private var totalDayCount: Int = 0
    @State private var daysLimit: Int?

    init(hourlyAggregate: HourlyAggregate? = nil) {
        _hourlyAggregate = State(initialValue: hourlyAggregate)
    }

    enum HistoryViewMode {
        case list, grid
    }

    private var allSummaries: [ArchivedPetSummary] {
        archivedPetManager.summaries
    }

    private var activePet: Pet? {
        petManager.currentPet
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                    .padding(.horizontal, 20)

                dailyPatternSection

                EssenceCollectionCarousel(
                    records: archivedPetManager.essenceRecords(currentPet: petManager.currentPet),
                    onTap: { record in
                        selectedEssenceRecord = record
                    }
                )
                .padding(.horizontal, 20)

                activeSection
                    .padding(.horizontal, 20)

                historySection
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(ThemeRadialBackground())
        .task {
            archivedPetManager.loadSummariesIfNeeded()
            loadTotalDayCount()
            await loadHourlyAggregate()
        }
        .fullScreenCover(item: $selectedActivePet) { pet in
            PetDetailScreen(
                pet: pet,
                showHomeShortcut: true,
                onAction: { handlePetAction($0, for: pet) }
            )
        }
        .fullScreenCover(item: $selectedArchivedPet) { pet in
            ArchivedPetDetailScreen(pet: pet)
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .sheet(item: $selectedEssenceRecord) { record in
            EssenceDetailSheet(
                record: record,
                summaries: archivedPetManager.summaries
            )
        }
        .onChange(of: petManager.currentPet?.id) {
            hourlyAggregate = nil
            totalDayCount = 0
            loadTotalDayCount()
            Task { await loadHourlyAggregate() }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            refreshTick += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshTick += 1
            loadTotalDayCount()
            Task { await loadHourlyAggregate(force: true) }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.system(size: 32, weight: .bold))
                Text("History of your pets and screen time.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current")
                .font(.headline)

            if let pet = activePet {
                ActivePetRow(refreshTick: refreshTick) {
                    selectedActivePet = pet
                }
            } else {
                emptyActiveState
            }
        }
    }

    private var emptyActiveState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No active pet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Create a new pet on the homepage.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    @ViewBuilder
    private var dailyPatternSection: some View {
        if let aggregate = hourlyAggregate, aggregate.dayCount >= 1 {
            DailyPatternCard(aggregate: aggregate, totalDayCount: totalDayCount, daysLimit: $daysLimit)
                .padding(.horizontal, 20)
                .onChange(of: daysLimit) {
                    Task { await loadHourlyAggregate(force: true) }
                }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("History")
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
                                    selectedArchivedPet = await archivedPetManager.loadDetail(for: summary)
                                }
                            }
                        }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(allSummaries) { summary in
                            ArchivedPetGridItem(pet: summary) {
                                Task {
                                    selectedArchivedPet = await archivedPetManager.loadDetail(for: summary)
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
            Text("No history yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Archived pets will appear here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Hourly Aggregate

    private func loadTotalDayCount() {
        let history = SharedDefaults.hourlyHistory
        if !history.isEmpty {
            totalDayCount = history.count
            return
        }
        if let allTime = SharedDefaults.hourlyAggregate(daysLimit: nil) {
            totalDayCount = allTime.dayCount
        }
    }

    private func loadHourlyAggregate(force: Bool = false) async {
        // Skip if already set (e.g. from init for previews) unless forced
        if !force && hourlyAggregate != nil { return }

        // Use cache if fresh (computed today)
        if !force && !SharedDefaults.isHourlyAggregateStale(daysLimit: daysLimit),
           let cached = SharedDefaults.hourlyAggregate(daysLimit: daysLimit) {
            hourlyAggregate = cached
            return
        }

        let store = SnapshotStore.shared
        let limit = daysLimit
        let computed = await Task.detached(priority: .userInitiated) {
            // Combine local snapshots (today) with synced history (past days)
            let history = SharedDefaults.hourlyHistory
            let todayBreakdown = store.computeTodayBreakdown()

            // Merge: history as base, today's snapshot as overlay (freshest)
            var byDate: [String: DailyHourlyBreakdown] = [:]
            for entry in history { byDate[entry.date] = entry }
            if let today = todayBreakdown { byDate[today.date] = today }

            let allDays = Array(byDate.values)
            guard !allDays.isEmpty else { return HourlyAggregate.empty }
            return HourlyAggregate.fromBreakdowns(allDays, daysLimit: limit)
        }.value

        #if DEBUG
        print("[Overview] result: dayCount=\(computed.dayCount), avg=\(Int(computed.totalDailyAverage))m")
        #endif
        SharedDefaults.setHourlyAggregate(computed, daysLimit: limit)
        hourlyAggregate = computed
    }

    // MARK: - Actions

    private func handlePetAction(_ action: PetDetailAction, for pet: Pet) {
        switch action {
        case .showOnHomepage, .blowAway, .replay, .progress, .archive:
            selectedActivePet = nil
            if let url = URL(string: DeepLinks.pet(pet.id)) {
                UIApplication.shared.open(url)
            }
        case .delete, .breakHistory:
            break
        }
    }
}

#if DEBUG
#Preview {
    OverviewScreen(hourlyAggregate: .mock())
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(StoreManager.mock())
}
#endif
