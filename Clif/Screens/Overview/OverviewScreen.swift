import SwiftUI

struct OverviewScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager

    @State private var selectedActivePet: Pet?
    @State private var selectedArchivedPet: ArchivedPet?
    @State private var historyViewMode: HistoryViewMode = .list

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

                EssenceCollectionCarousel(
                    records: archivedPetManager.essenceRecords(currentPet: petManager.currentPet)
                )
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
            PetDetailScreen(
                pet: pet,
                showOverviewActions: true,
                onAction: { handlePetAction($0, for: pet) }
            )
        }
        .fullScreenCover(item: $selectedArchivedPet) { pet in
            ArchivedPetDetailScreen(pet: pet)
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
            Text("Aktuální")
                .font(.headline)

            if let pet = activePet {
                ActivePetRow(pet: pet) {
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
            Text("Žádný aktivní pet")
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

    private func handlePetAction(_ action: PetDetailAction, for pet: Pet) {
        switch action {
        case .showOnHomepage:
            selectedActivePet = nil
            if let url = URL(string: DeepLinks.pet(pet.id)) {
                UIApplication.shared.open(url)
            }
        case .blowAway, .replay, .delete, .progress, .breakHistory:
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
