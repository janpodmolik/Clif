import FamilyControls
import SwiftUI

struct OverviewScreen: View {
    @State private var selectedPet: ArchivedDailyPet?
    @State private var selectedDailyPet: DailyPet?
    @State private var historyViewMode: HistoryViewMode = .list

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared

    enum HistoryViewMode {
        case list, grid
    }

    // Mock data for now - stored in @State to prevent regeneration on view updates
    @State private var weeklyStats = WeeklyUsageStats.mock()
    @State private var archivedPets = ArchivedDailyPet.mockList()
    @State private var activePets = DailyPet.mockList()

    private var completedPets: [ArchivedDailyPet] {
        archivedPets.filter { !$0.isBlown }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                    .padding(.horizontal, 20)

                PetScreenTimeCarousel(
                    activePets: activePets,
                    fallbackStats: weeklyStats,
                    applicationTokens: screenTimeManager.activitySelection.applicationTokens,
                    categoryTokens: screenTimeManager.activitySelection.categoryTokens,
                    onPetTap: { pet in
                        selectedDailyPet = pet
                    }
                )

                HistoryIslandsCarousel(pets: completedPets) { pet in
                    selectedPet = pet
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
        .fullScreenCover(item: $selectedPet) { pet in
            PetArchivedDetailScreen(pet: pet)
        }
        .fullScreenCover(item: $selectedDailyPet) { pet in
            PetActiveDetailScreen(
                pet: pet,
                showOverviewActions: true,
                onShowOnHomepage: {
                    selectedDailyPet = nil
                    if let url = URL(string: "clif://pet/\(pet.id.uuidString)") {
                        UIApplication.shared.open(url)
                    }
                }
            )
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
                        PetActiveRow(pet: pet) {
                            selectedDailyPet = pet
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

                Text("\(archivedPets.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if archivedPets.isEmpty {
                emptyHistoryState
            } else {
                if historyViewMode == .list {
                    LazyVStack(spacing: 12) {
                        ForEach(archivedPets) { pet in
                            PetHistoryRow(pet: pet) {
                                selectedPet = pet
                            }
                        }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(archivedPets) { pet in
                            PetHistoryGridItem(pet: pet) {
                                selectedPet = pet
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
}
