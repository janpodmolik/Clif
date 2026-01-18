import SwiftUI

struct DynamicPetDetailScreen: View {
    let pet: DynamicPet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onAction: (DynamicPetDetailAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var showEssencePicker = false

    private var mood: Mood {
        pet.isBlown ? .blown : Mood(from: pet.windLevel)
    }

    private var themeColor: Color {
        pet.themeColor
    }

    /// canUseEssence for blob, canEvolve for evolved
    private var canProgress: Bool {
        pet.isBlob ? pet.canUseEssence : pet.canEvolve
    }

    /// daysUntilEssence for blob, daysUntilEvolution for evolved
    private var daysUntilProgress: Int? {
        pet.isBlob ? pet.daysUntilEssence : pet.daysUntilEvolution
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // TODO: WindProgressCard (Dynamic-specific)
                    windProgressPlaceholder

                    // TODO: BreakButton / BreakCountdownCard (Dynamic-specific)
                    if pet.activeBreak != nil {
                        breakCountdownPlaceholder
                    } else {
                        breakButtonPlaceholder
                    }

                    PetDetailHeader(
                        petName: pet.name,
                        mood: mood,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.currentPhase,
                        purposeLabel: pet.purpose,
                        createdAt: pet.evolutionHistory.createdAt
                    )

                    if pet.isBlob {
                        NoEssenceCard {
                            // TODO: Navigate to inventory
                        }
                    } else {
                        EssenceInfoCard(evolutionHistory: pet.evolutionHistory)
                    }

                    EvolutionCarousel(
                        pet: pet,
                        mood: mood,
                        canUseEssence: pet.canUseEssence
                    )

                    if !pet.isBlob {
                        EvolutionTimelineView(
                            history: pet.evolutionHistory,
                            canEvolve: canProgress,
                            daysUntilEvolution: daysUntilProgress
                        )
                    }

                    // TODO: WindHistoryChart (Dynamic-specific)
                    windHistoryPlaceholder

                    // TODO: BreakHistoryList (Dynamic-specific)
                    if !pet.breakHistory.isEmpty {
                        breakHistoryPlaceholder
                    }

                    LimitedAppsBadge(
                        appCount: pet.limitedAppCount,
                        onTap: { onAction(.limitedApps) }
                    )

                    if showOverviewActions {
                        overviewActions
                    } else {
                        PetDetailActions(
                            isBlob: pet.isBlob,
                            canProgress: canProgress,
                            daysUntilProgress: daysUntilProgress,
                            isBlownAway: pet.isBlown,
                            onProgress: pet.isBlob ? { showEssencePicker = true } : { pet.evolve() },
                            onBlowAway: { onAction(.blowAway) },
                            onReplay: { onAction(.replay) },
                            onDelete: { onAction(.delete) }
                        )
                    }
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
            .sheet(isPresented: $showEssencePicker) {
                EssencePickerSheet { essence in
                    pet.applyEssence(essence)
                }
            }
        }
    }

    // MARK: - Placeholder Components (to be replaced)

    private var windProgressPlaceholder: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Wind")
                    .font(.headline)
                Spacer()
                Text("\(Int(pet.windPoints))/100")
                    .font(.system(.title3, design: .monospaced, weight: .bold))
            }

            ProgressView(value: pet.windProgress)
                .tint(pet.windLevel.color)

            HStack {
                Text(pet.windLevel.displayName)
                    .font(.subheadline)
                    .foregroundStyle(pet.windLevel.color)
                Spacer()
                if pet.isBlownAway {
                    Text("Blown Away")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var breakButtonPlaceholder: some View {
        Button {
            onAction(.startBreak)
        } label: {
            HStack {
                Image(systemName: "pause.circle.fill")
                Text("Take a Break")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(pet.windProgress > 0.5 ? Color.cyan : Color.secondary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var breakCountdownPlaceholder: some View {
        VStack(spacing: 8) {
            if let activeBreak = pet.activeBreak {
                HStack {
                    Image(systemName: "timer")
                    Text("Break in progress")
                        .font(.headline)
                    Spacer()
                    Text(activeBreak.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2), in: Capsule())
                }

                if let remainingSeconds = activeBreak.remainingSeconds {
                    let remainingMinutes = Int(remainingSeconds / 60)
                    Text("\(remainingMinutes) min remaining")
                        .font(.system(.title2, design: .monospaced))
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var windHistoryPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wind History")
                .font(.headline)

            Text("Chart coming soon...")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .glassCard()
    }

    private var breakHistoryPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Break History")
                    .font(.headline)
                Spacer()
                Text("\(pet.breakHistory.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(pet.breakHistory.prefix(3)) { completedBreak in
                HStack {
                    Image(systemName: completedBreak.wasViolated ? "xmark.circle" : "checkmark.circle")
                        .foregroundStyle(completedBreak.wasViolated ? .red : .green)
                    Text(completedBreak.type.displayName)
                    Spacer()
                    Text("-\(Int(completedBreak.windDecreased)) wind")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Overview Actions

    @ViewBuilder
    private var overviewActions: some View {
        if pet.isBlown {
            overviewBlownAwayActions
        } else {
            overviewNormalActions
        }
    }

    private var overviewNormalActions: some View {
        HStack(spacing: 16) {
            Button { onAction(.delete) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { onAction(.showOnHomepage) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text("Zobrazit")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(themeColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeColor.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }

    private var overviewBlownAwayActions: some View {
        HStack(spacing: 16) {
            Button { onAction(.replay) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "memories")
                    Text("Replay")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { onAction(.delete) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Smazat")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }
}

#if DEBUG
#Preview("Dynamic Pet Detail") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Fern", phase: 2, windPoints: 45))
        }
}

#Preview("With Active Break") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mockWithBreak())
        }
}

#Preview("High Wind") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Willow", phase: 3, windPoints: 85))
        }
}

#Preview("Overview Actions") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Ivy", phase: 3, windPoints: 30), showOverviewActions: true)
        }
}
#endif
