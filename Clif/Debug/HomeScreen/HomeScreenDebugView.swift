#if DEBUG
import SwiftUI

struct HomeScreenDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Wind Rhythm

    @State private var windRhythm = WindRhythm()

    // MARK: - Pet State

    @State private var selectedEvolutionType: EvolutionTypeOption = .blob
    @State private var plantPhase: Int = 1

    // MARK: - Card State

    @State private var petName: String = "Blob"
    @State private var purposeLabel: String = "Social Media"
    @State private var streakCount: Int = 7
    @State private var usedMinutes: Double = 32
    @State private var limitMinutes: Double = 120
    @State private var showEvolveButton: Bool = true
    @State private var daysUntilEvolution: Int = 3
    @State private var isBlownAway: Bool = false

    // MARK: - Panel State

    @State private var panelState: PanelState = .medium
    @State private var isPetSectionExpanded: Bool = true
    @State private var isCardSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Detail Sheet

    @State private var showPetDetail: Bool = false

    // MARK: - Enums

    enum EvolutionTypeOption: String, CaseIterable {
        case blob = "Blob"
        case plant = "Plant"
    }

    enum PanelState: CaseIterable {
        case minimized
        case medium
        case fullscreen

        var next: PanelState {
            switch self {
            case .minimized: return .medium
            case .medium: return .fullscreen
            case .fullscreen: return .minimized
            }
        }

        var chevronIcon: String {
            switch self {
            case .minimized: return "chevron.up"
            case .medium: return "chevron.up.chevron.down"
            case .fullscreen: return "chevron.down"
            }
        }
    }

    // MARK: - Computed Properties

    private var currentPet: any PetDisplayable {
        switch selectedEvolutionType {
        case .blob:
            return Blob.shared
        case .plant:
            return EvolutionPath.plant.phase(at: plantPhase) ?? Blob.shared
        }
    }

    private var evolutionStage: Int {
        switch selectedEvolutionType {
        case .blob: return 0
        case .plant: return plantPhase
        }
    }

    private var windProgress: CGFloat {
        guard limitMinutes > 0 else { return 0 }
        return CGFloat(usedMinutes / limitMinutes)
    }

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var currentMood: Mood {
        if isBlownAway { return .blown }
        return Mood(from: windLevel)
    }

    private var progress: Double {
        guard limitMinutes > 0 else { return 0 }
        return usedMinutes / limitMinutes
    }

    private var usedTimeText: String {
        formatTime(minutes: Int(usedMinutes))
    }

    private var dailyLimitText: String {
        formatTime(minutes: Int(limitMinutes))
    }

    private var currentEssence: Essence? {
        switch selectedEvolutionType {
        case .blob: return nil
        case .plant: return .plant
        }
    }

    private var debugPet: DailyPet {
        let pet = DailyPet(
            name: petName,
            evolutionHistory: EvolutionHistory(
                createdAt: Calendar.current.date(byAdding: .day, value: -streakCount, to: Date())!,
                essence: currentEssence,
                events: []
            ),
            purpose: purposeLabel,
            todayUsedMinutes: Int(usedMinutes),
            dailyLimitMinutes: Int(limitMinutes)
        )
        if isBlownAway {
            pet.blowAway()
        }
        return pet
    }

    private var debugActivePet: ActivePet {
        .daily(debugPet)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    if colorScheme == .dark {
                        NightBackgroundView()
                    } else {
                        DayBackgroundView()
                    }

                    // Wind lines
                    WindLinesView(
                        windProgress: windProgress,
                        direction: 1.0,
                        windAreaTop: 0.25,
                        windAreaBottom: 0.50,
                        windRhythm: windRhythm
                    )

                    // Island with pet
                    IslandView(
                        screenHeight: geometry.size.height,
                        screenWidth: geometry.size.width,
                        pet: currentPet,
                        windProgress: windProgress,
                        windDirection: 1.0,
                        windRhythm: windRhythm
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)

                    // Home card
                    HomeCardView(
                        pet: debugActivePet,
                        streakCount: streakCount,
                        showDetailButton: true,
                        onAction: { action in
                            if action == .detail {
                                showPetDetail = true
                            } else {
                                print("\(action) tapped")
                            }
                        }
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(16)

                    // Debug controls panel
                    debugControlsPanel(
                        screenHeight: geometry.size.height,
                        safeAreaTop: geometry.safeAreaInsets.top
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("HomeScreen Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            DailyPetDetailScreen(pet: debugPet)
        }
        .onAppear {
            windRhythm.start()
        }
        .onDisappear {
            windRhythm.stop()
        }
    }

    // MARK: - Debug Controls Panel

    private func debugControlsPanel(screenHeight: CGFloat, safeAreaTop: CGFloat) -> some View {
        let fullscreenTopOffset = safeAreaTop + 44 + 20

        return VStack(spacing: 0) {
            if panelState == .fullscreen {
                Color.clear.frame(height: fullscreenTopOffset)
            } else {
                Spacer()
            }

            VStack(spacing: 12) {
                // Drag handle
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    HStack {
                        Text("HomeScreen Debug")
                            .font(.headline)

                        Spacer()

                        Image(systemName: panelState.chevronIcon)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        panelState = panelState.next
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if value.translation.height > 50 {
                                    switch panelState {
                                    case .fullscreen: panelState = .medium
                                    case .medium: panelState = .minimized
                                    case .minimized: break
                                    }
                                } else if value.translation.height < -50 {
                                    switch panelState {
                                    case .minimized: panelState = .medium
                                    case .medium: panelState = .fullscreen
                                    case .fullscreen: break
                                    }
                                }
                            }
                        }
                )

                if panelState != .minimized {
                    controlsContent
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var controlsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Pet Section
                collapsibleSection(
                    title: "Pet & Wind",
                    systemImage: "leaf.fill",
                    isExpanded: $isPetSectionExpanded
                ) {
                    petSectionContent
                }

                // Card Section
                collapsibleSection(
                    title: "Card Data",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    isExpanded: $isCardSectionExpanded
                ) {
                    cardSectionContent
                }

                // Presets Section
                collapsibleSection(
                    title: "Quick Presets",
                    systemImage: "sparkles.rectangle.stack",
                    isExpanded: $isPresetsSectionExpanded
                ) {
                    presetsSectionContent
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: panelState == .fullscreen ? .infinity : 350)
    }

    // MARK: - Pet Section

    @ViewBuilder
    private var petSectionContent: some View {
        VStack(spacing: 12) {
            // Evolution type selector
            DebugSegmentedPicker(
                EvolutionTypeOption.allCases.map { $0 },
                selection: $selectedEvolutionType,
                label: { $0.rawValue }
            )
            .onChange(of: selectedEvolutionType) { _, newValue in
                petName = newValue == .blob ? "Blob" : "Fern"
            }

            // Phase selector (only for plant)
            if selectedEvolutionType == .plant {
                HStack {
                    Text("Phase")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Phase", selection: $plantPhase) {
                        ForEach(1...4, id: \.self) { phase in
                            Text("\(phase)").tag(phase)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }

            // Wind level (computed from used/limit)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Wind")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(windProgress * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(windLevel.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(windLevel.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(windLevel.color.opacity(0.2))
                        .cornerRadius(4)
                    Text("Mood: \(currentMood.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(moodColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }

    private var moodColor: Color {
        switch currentMood {
        case .happy: return .green
        case .neutral: return .yellow
        case .sad, .blown: return .red
        }
    }

    // MARK: - Card Section

    @ViewBuilder
    private var cardSectionContent: some View {
        VStack(spacing: 12) {
            // Pet name
            HStack {
                Text("Name")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Pet name", text: $petName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .multilineTextAlignment(.trailing)
            }

            // Purpose label
            HStack {
                Text("Purpose")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("e.g. Social Media", text: $purposeLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .multilineTextAlignment(.trailing)
            }

            // Streak
            HStack {
                Text("Streak")
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        if streakCount > 0 { streakCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(streakCount)")
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .frame(width: 40)

                    Button {
                        streakCount += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            // Used time slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Used")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(usedTimeText)
                        .font(.system(.body, design: .monospaced))
                }
                Slider(value: $usedMinutes, in: 0...300, step: 1)
            }

            // Limit slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Limit")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dailyLimitText)
                        .font(.system(.body, design: .monospaced))
                }
                Slider(value: $limitMinutes, in: 1...480, step: 1)
            }

            // Progress display
            HStack {
                Text("Progress")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(progressColor)
            }

            Divider()

            // Blown away toggle
            Toggle("Blown Away State", isOn: $isBlownAway)

            if !isBlownAway {
                // Evolve button toggle
                Toggle("Show Evolve Button", isOn: $showEvolveButton)

                if !showEvolveButton {
                    HStack {
                        Text("Days Until Evolution")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper("\(daysUntilEvolution)", value: $daysUntilEvolution, in: 1...30)
                            .frame(width: 120)
                    }
                }
            }
        }
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    // MARK: - Presets Section

    @ViewBuilder
    private var presetsSectionContent: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            presetButton("Blob Ready", color: .mint) { applyBlobReadyPreset() }
            presetButton("Plant Phase 1", color: .green) { applyPlantPhase1Preset() }
            presetButton("Plant Phase 4", color: .purple) { applyPlantPhase4Preset() }
            presetButton("Critical", color: .orange) { applyCriticalPreset() }
            presetButton("Blown Away", color: .red) { applyBlownAwayPreset() }
            presetButton("New Pet", color: .blue) { applyNewPetPreset() }
        }
    }

    private func presetButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset Actions

    private func applyBlobReadyPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .blob
            petName = "Blob"
            purposeLabel = "Social Media"
            streakCount = 7
            usedMinutes = 0  // 0% = none zone
            limitMinutes = 120
            showEvolveButton = true
            isBlownAway = false
        }
    }

    private func applyPlantPhase1Preset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .plant
            plantPhase = 1
            petName = "Sprout"
            purposeLabel = "Gaming"
            streakCount = 14
            usedMinutes = 60  // ~33% = low zone
            limitMinutes = 180
            showEvolveButton = false
            daysUntilEvolution = 3
            isBlownAway = false
        }
    }

    private func applyPlantPhase4Preset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .plant
            plantPhase = 4
            petName = "Elder Oak"
            purposeLabel = "Work Apps"
            streakCount = 30
            usedMinutes = 100  // ~55% = medium zone
            limitMinutes = 180
            showEvolveButton = false
            isBlownAway = false
        }
    }

    private func applyCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .plant
            plantPhase = 2
            petName = "Willow"
            purposeLabel = "Streaming"
            streakCount = 5
            usedMinutes = 160  // ~89% = high zone
            limitMinutes = 180
            showEvolveButton = false
            isBlownAway = false
        }
    }

    private func applyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .plant
            plantPhase = 3
            petName = "Willow"
            purposeLabel = "Social Media"
            streakCount = 0
            usedMinutes = 230  // >100% = high zone
            limitMinutes = 180
            showEvolveButton = false
            isBlownAway = true
        }
    }

    private func applyNewPetPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedEvolutionType = .blob
            petName = "Blob"
            purposeLabel = ""
            streakCount = 0
            usedMinutes = 0  // 0% = none zone
            limitMinutes = 180
            showEvolveButton = false
            daysUntilEvolution = 7
            isBlownAway = false
        }
    }

    // MARK: - Helpers

    private func formatTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
                    .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeScreenDebugView()
}
#endif
