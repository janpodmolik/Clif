#if DEBUG
import SwiftUI

struct PetDetailScreenDebug: View {
    private enum DebugPetMode: String, CaseIterable {
        case daily
        case dynamic

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .dynamic: return "Dynamic"
            }
        }
    }
    @Environment(\.dismiss) private var dismiss

    // MARK: - Mode Selection

    @State private var petMode: DebugPetMode = .daily

    // MARK: - Pet Identity State

    @State private var petName: String = "Fern"
    @State private var purposeLabel: String = "Social Media"
    @State private var isBlob: Bool = false
    @State private var essence: Essence = .plant
    @State private var currentPhase: Int = 2
    @State private var totalDays: Int = 12

    // MARK: - Daily Mode State

    @State private var todayUsedMinutes: Double = 83
    @State private var dailyLimitMinutes: Double = 180

    // MARK: - Dynamic Mode State

    @State private var windPoints: Double = 45
    @State private var windConfig: DynamicModeConfig = .balanced
    @State private var hasActiveBreak: Bool = false
    @State private var breakType: BreakType = .committed
    @State private var breakMinutesAgo: Double = 5
    @State private var breakDurationMinutes: Int = 30

    // MARK: - Pet State

    @State private var isBlownAway: Bool = false

    // MARK: - Section Expansion

    @State private var isPetSectionExpanded: Bool = true
    @State private var isWeatherSectionExpanded: Bool = true
    @State private var isTimeSectionExpanded: Bool = true
    @State private var isBreakSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Sheet State

    @State private var showSheet: Bool = false

    // MARK: - Computed Properties (Daily)

    private var dailyWindProgress: CGFloat {
        dailyLimitMinutes > 0 ? CGFloat(todayUsedMinutes / dailyLimitMinutes) : 0
    }

    private var dailyWindLevel: WindLevel {
        WindLevel.from(progress: dailyWindProgress)
    }

    // MARK: - Computed Properties (Dynamic)

    private var dynamicWindProgress: CGFloat {
        CGFloat(min(max(windPoints / 100.0, 0), 1.0))
    }

    private var dynamicWindLevel: WindLevel {
        WindLevel.from(progress: dynamicWindProgress)
    }

    private var dynamicConfig: DynamicModeConfig {
        windConfig
    }

    private var activeBreak: ActiveBreak? {
        guard hasActiveBreak else { return nil }
        return ActiveBreak.mock(
            type: breakType,
            minutesAgo: breakMinutesAgo,
            durationMinutes: breakDurationMinutes
        )
    }

    // MARK: - Computed Properties (Shared)

    private var currentWindProgress: CGFloat {
        petMode == .daily ? dailyWindProgress : dynamicWindProgress
    }

    private var currentWindLevel: WindLevel {
        petMode == .daily ? dailyWindLevel : dynamicWindLevel
    }

    private var mood: Mood {
        isBlownAway ? .blown : Mood(from: currentWindLevel)
    }

    private var effectiveEssence: Essence? {
        isBlob ? nil : essence
    }

    private var effectivePhase: Int {
        isBlob ? 0 : currentPhase
    }

    private var evolutionHistory: EvolutionHistory {
        if isBlob {
            return EvolutionHistory(
                createdAt: Calendar.current.date(byAdding: .day, value: -totalDays, to: Date())!,
                essence: nil,
                events: [],
                blownAt: isBlownAway ? Date() : nil
            )
        }

        let events: [EvolutionEvent] = currentPhase > 1
            ? (2...currentPhase).map { phase in
                let daysAgo = (currentPhase - phase + 1) * 3
                return EvolutionEvent(
                    fromPhase: phase - 1,
                    toPhase: phase,
                    date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
                )
            }
            : []

        return EvolutionHistory(
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            essence: essence,
            events: events,
            blownAt: isBlownAway ? Date() : nil
        )
    }

    private var evolutionPath: EvolutionPath? {
        guard let essence = effectiveEssence else { return nil }
        return EvolutionPath.path(for: essence)
    }

    private var dailyStats: [DailyUsageStat] {
        DailyUsageStat.mockList(
            petId: UUID(),
            days: totalDays,
            dailyLimitMinutes: Int(dailyLimitMinutes),
            wasBlown: isBlownAway
        )
    }

    private var debugDailyPet: DailyPet {
        DailyPet(
            name: petName,
            evolutionHistory: evolutionHistory,
            purpose: purposeLabel.isEmpty ? nil : purposeLabel,
            todayUsedMinutes: Int(todayUsedMinutes),
            dailyLimitMinutes: Int(dailyLimitMinutes),
            dailyStats: dailyStats
        )
    }

    private var debugDynamicPet: DynamicPet {
        let pet = DynamicPet(
            name: petName,
            evolutionHistory: evolutionHistory,
            purpose: purposeLabel.isEmpty ? nil : purposeLabel,
            windPoints: windPoints,
            config: dynamicConfig,
            dailyStats: dailyStats
        )
        pet.activeBreak = activeBreak
        return pet
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                previewSection
                    .frame(maxHeight: .infinity)

                Divider()

                controlsPanel
            }
        }
        .navigationTitle("PetDetail Debug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showSheet) {
            if petMode == .daily {
                DailyPetDetailScreen(
                    pet: debugDailyPet,
                    onAction: { action in
                        print("Daily Action: \(action)")
                    }
                )
            } else {
                DynamicPetDetailScreen(
                    pet: debugDynamicPet,
                    onAction: { action in
                        print("Dynamic Action: \(action)")
                    }
                )
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            LinearGradient(
                colors: petMode == .daily
                    ? [.blue.opacity(0.3), .purple.opacity(0.2)]
                    : [.orange.opacity(0.3), .red.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text(petName)
                        .font(.title2.weight(.bold))

                    HStack(spacing: 16) {
                        if let path = evolutionPath {
                            Label("Phase \(currentPhase)/\(path.maxPhases)", systemImage: "sparkles")
                        } else {
                            Label("Blob", systemImage: "circle.fill")
                                .foregroundStyle(.gray)
                        }
                        Label("\(totalDays) days", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    // Mode indicator
                    Text(petMode == .daily ? "Daily Mode" : "Dynamic Mode")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(petMode == .daily ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

                Button {
                    showSheet = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open Pet Detail Sheet")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(petMode == .daily ? .blue : .orange, in: Capsule())
                }
            }
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                modePickerSection
                petIdentitySection

                if petMode == .daily {
                    dailyWeatherSection
                    screenTimeSection
                } else {
                    dynamicWeatherSection
                    breakSection
                }

                presetsSection
            }
            .padding()
        }
        .frame(height: 420)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Mode Picker Section

    private var modePickerSection: some View {
        VStack(spacing: 8) {
            Picker("Mode", selection: $petMode) {
                ForEach(DebugPetMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pet Identity Section

    private var petIdentitySection: some View {
        collapsibleSection(
            title: "Pet Identity",
            systemImage: "leaf.fill",
            isExpanded: $isPetSectionExpanded
        ) {
            VStack(spacing: 12) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Pet name", text: $petName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Purpose")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. Social Media", text: $purposeLabel)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                Toggle("Blob (no essence)", isOn: $isBlob)

                if !isBlob, let path = evolutionPath {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Evolution Phase")
                            .foregroundStyle(.secondary)

                        Picker("Phase", selection: $currentPhase) {
                            ForEach(1...path.maxPhases, id: \.self) { phase in
                                Text("\(phase)").tag(phase)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                HStack {
                    Text("Total Days")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if totalDays > 0 { totalDays -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(totalDays)")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .frame(width: 40)

                        Button {
                            totalDays += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Toggle("Blown Away", isOn: $isBlownAway)
            }
        }
    }

    // MARK: - Daily Weather Section

    private var dailyWeatherSection: some View {
        collapsibleSection(
            title: "Weather",
            systemImage: "wind",
            isExpanded: $isWeatherSectionExpanded
        ) {
            VStack(spacing: 12) {
                HStack {
                    Text("Wind Level")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dailyWindLevel.displayName)
                        .foregroundStyle(dailyWindLevel.color)
                        .font(.system(.body, weight: .semibold))
                }

                HStack {
                    Text("Wind Progress")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(dailyWindProgress * 100))%")
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Pet Mood")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(mood.emoji)
                        .font(.title2)
                    Text(mood.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }

                Text("Wind level is computed from Screen Time progress")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Dynamic Weather Section

    private var dynamicWeatherSection: some View {
        collapsibleSection(
            title: "Wind Points",
            systemImage: "wind",
            isExpanded: $isWeatherSectionExpanded
        ) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Wind Points")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(windPoints))/100")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundStyle(progressColor(for: windPoints / 100))
                    }
                    Slider(value: $windPoints, in: 0...100, step: 1)
                        .tint(.orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind Config")
                        .foregroundStyle(.secondary)

                    Picker("Config", selection: $windConfig) {
                        ForEach(DynamicModeConfig.allCases, id: \.self) { config in
                            Text(config.displayName).tag(config)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Blow: \(Int(windConfig.minutesToBlowAway)) min • Recover: \(Int(windConfig.minutesToRecover)) min")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Text("Wind Level")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dynamicWindLevel.displayName)
                        .foregroundStyle(dynamicWindLevel.color)
                        .font(.system(.body, weight: .semibold))
                }

                HStack {
                    Text("Pet Mood")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(mood.emoji)
                        .font(.title2)
                    Text(mood.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Screen Time Section (Daily)

    private var screenTimeSection: some View {
        collapsibleSection(
            title: "Screen Time",
            systemImage: "clock",
            isExpanded: $isTimeSectionExpanded
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Used Today")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatTime(minutes: Int(todayUsedMinutes)))
                            .font(.system(.body, design: .monospaced))
                    }
                    Slider(value: $todayUsedMinutes, in: 0...300, step: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Limit")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatTime(minutes: Int(dailyLimitMinutes)))
                            .font(.system(.body, design: .monospaced))
                    }
                    Slider(value: $dailyLimitMinutes, in: 1...480, step: 1)
                }

                HStack {
                    Text("Progress")
                        .foregroundStyle(.secondary)
                    Spacer()
                    let progress = todayUsedMinutes / dailyLimitMinutes
                    Text("\(Int(progress * 100))%")
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .foregroundStyle(progressColor(for: progress))
                }
            }
        }
    }

    // MARK: - Break Section (Dynamic)

    private var breakSection: some View {
        collapsibleSection(
            title: "Break",
            systemImage: "pause.circle",
            isExpanded: $isBreakSectionExpanded
        ) {
            VStack(spacing: 12) {
                Toggle("Active Break", isOn: $hasActiveBreak)

                if hasActiveBreak {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Type")
                            .foregroundStyle(.secondary)

                        Picker("Type", selection: $breakType) {
                            ForEach(BreakType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack {
                        Text("Started")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(breakMinutesAgo)) min ago")
                            .font(.system(.body, design: .monospaced))
                    }

                    Slider(value: $breakMinutesAgo, in: 0...60, step: 1) {
                        Text("Minutes Ago")
                    }

                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Duration", selection: $breakDurationMinutes) {
                            ForEach(ActiveBreak.availableDurations, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if let activeBreak = activeBreak {
                        HStack {
                            Text("Wind Decrease")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("-\(String(format: "%.1f", activeBreak.windDecreased(for: windConfig))) pts")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        collapsibleSection(
            title: "Quick Presets",
            systemImage: "sparkles.rectangle.stack",
            isExpanded: $isPresetsSectionExpanded
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if petMode == .daily {
                    presetButton("Normal", color: .blue) { applyDailyNormalPreset() }
                    presetButton("Evolve Ready", color: .green) { applyDailyEvolveReadyPreset() }
                    presetButton("Max Evolution", color: .purple) { applyDailyMaxEvolutionPreset() }
                    presetButton("Blob", color: .gray) { applyDailyBlobPreset() }
                    presetButton("Critical", color: .orange) { applyDailyCriticalPreset() }
                    presetButton("Blown Away", color: .red) { applyDailyBlownAwayPreset() }
                } else {
                    presetButton("Calm", color: .green) { applyDynamicCalmPreset() }
                    presetButton("Rising Wind", color: .yellow) { applyDynamicRisingPreset() }
                    presetButton("Blob", color: .gray) { applyDynamicBlobPreset() }
                    presetButton("On Break", color: .blue) { applyDynamicBreakPreset() }
                    presetButton("Critical", color: .orange) { applyDynamicCriticalPreset() }
                    presetButton("Blown Away", color: .red) { applyDynamicBlownAwayPreset() }
                }
            }
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

    // MARK: - Daily Presets

    private func applyDailyNormalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 2
            totalDays = 12
            todayUsedMinutes = 100
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyDailyEvolveReadyPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purposeLabel = "Gaming"
            isBlob = false
            currentPhase = 2
            totalDays = 7
            todayUsedMinutes = 60
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyDailyMaxEvolutionPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Elder Oak"
            purposeLabel = "Work Apps"
            isBlob = false
            currentPhase = 4
            totalDays = 30
            todayUsedMinutes = 0
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyDailyBlobPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Blobby"
            purposeLabel = "Social Media"
            isBlob = true
            totalDays = 1
            todayUsedMinutes = 40
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyDailyCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Streaming"
            isBlob = false
            currentPhase = 3
            totalDays = 5
            todayUsedMinutes = 160
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyDailyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 3
            totalDays = 0
            todayUsedMinutes = 230
            dailyLimitMinutes = 180
            isBlownAway = true
        }
    }

    // MARK: - Dynamic Presets

    private func applyDynamicCalmPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 2
            totalDays = 14
            windPoints = 15
            windConfig = .balanced
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyDynamicRisingPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Gaming"
            isBlob = false
            currentPhase = 2
            totalDays = 10
            windPoints = 55
            windConfig = .balanced
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyDynamicBlobPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Blobby"
            purposeLabel = "Social Media"
            isBlob = true
            totalDays = 1
            windPoints = 25
            windConfig = .gentle
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyDynamicBreakPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 2
            totalDays = 8
            windPoints = 65
            windConfig = .balanced
            hasActiveBreak = true
            breakType = .committed
            breakMinutesAgo = 10
            breakDurationMinutes = 30
            isBlownAway = false
        }
    }

    private func applyDynamicCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Streaming"
            isBlob = false
            currentPhase = 3
            totalDays = 5
            windPoints = 85
            windConfig = .intense
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyDynamicBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 3
            totalDays = 0
            windPoints = 100
            windConfig = .balanced
            hasActiveBreak = false
            isBlownAway = true
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

    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
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
    NavigationStack {
        PetDetailScreenDebug()
    }
}
#endif
