import FamilyControls
import SwiftUI

struct OverviewScreen: View {
    @State private var selectedPet: ArchivedPet?
    @State private var selectedActivePet: ActivePet?
    @State private var historyViewMode: HistoryViewMode = .list

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared

    enum HistoryViewMode {
        case list, grid
    }

    // Mock data for now
    private let weeklyStats = BlockedAppsWeeklyStats.mock()
    private let archivedPets = ArchivedPet.mockList()
    private let activePets = ActivePet.mockList()

    private var completedPets: [ArchivedPet] {
        archivedPets.filter { !$0.isBlown }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                ScreenTimeOverviewCard(
                    stats: weeklyStats,
                    applicationTokens: screenTimeManager.activitySelection.applicationTokens,
                    categoryTokens: screenTimeManager.activitySelection.categoryTokens
                )

                HistoryIslandsCarousel(pets: completedPets) { pet in
                    selectedPet = pet
                }

                activeSection

                historySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(OverviewBackground())
        .fullScreenCover(item: $selectedPet) { pet in
            PetHistoryDetailScreen(pet: pet)
        }
        .fullScreenCover(item: $selectedActivePet) { pet in
            PetActiveDetailScreen(
                petName: pet.name,
                evolutionHistory: pet.evolutionHistory,
                streak: pet.streak,
                purposeLabel: pet.purpose,
                windLevel: pet.windLevel,
                isBlownAway: false,
                usedMinutes: pet.usedMinutes,
                limitMinutes: pet.limitMinutes,
                weeklyStats: pet.weeklyStats,
                blockedAppCount: pet.blockedAppCount,
                daysUntilEvolution: pet.daysUntilEvolution,
                showOverviewActions: true,
                onShowOnHomepage: {
                    selectedActivePet = nil
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
                            selectedActivePet = pet
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
