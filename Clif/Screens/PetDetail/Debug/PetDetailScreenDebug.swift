#if DEBUG
import SwiftUI

struct PetDetailScreenDebug: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Pet Identity State

    @State private var petName: String = "Fern"
    @State private var purposeLabel: String = "Social Media"
    @State private var isBlob: Bool = false
    @State private var essence: Essence = .plant
    @State private var currentPhase: Int = 2
    @State private var totalDays: Int = 12

    // MARK: - Wind State

    @State private var windPoints: Double = 45
    @State private var windPreset: WindPreset = .balanced
    @State private var hasActiveBreak: Bool = false
    @State private var breakType: BreakType = .committed
    @State private var breakMinutesAgo: Double = 5
    @State private var breakDurationMinutes: Int = 30

    // MARK: - Pet State

    @State private var isBlownAway: Bool = false

    // MARK: - Section Expansion

    @State private var isPetSectionExpanded: Bool = true
    @State private var isWeatherSectionExpanded: Bool = true
    @State private var isBreakSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Sheet State

    @State private var showSheet: Bool = false

    // MARK: - Computed Properties

    private var windProgress: CGFloat {
        CGFloat(min(max(windPoints / 100.0, 0), 1.0))
    }

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var activeBreak: ActiveBreak? {
        guard hasActiveBreak else { return nil }
        return ActiveBreak.mock(
            type: breakType,
            minutesAgo: breakMinutesAgo,
            durationMinutes: breakDurationMinutes
        )
    }

    private var effectiveEssence: Essence? {
        isBlob ? nil : essence
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
            wasBlown: isBlownAway
        )
    }

    private var debugPet: Pet {
        // Setup SharedDefaults for computed windPoints property
        let petId = UUID()
        Pet.setupMockDefaults(petId: petId, windPoints: windPoints)

        let pet = Pet(
            id: petId,
            name: petName,
            evolutionHistory: evolutionHistory,
            purpose: purposeLabel.isEmpty ? nil : purposeLabel,
            preset: windPreset,
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
            PetDetailScreen(
                pet: debugPet,
                onAction: { action in
                    print("Action: \(action)")
                }
            )
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            LinearGradient(
                colors: [.orange.opacity(0.3), .red.opacity(0.2)],
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
                    .background(.orange, in: Capsule())
                }
            }
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                petIdentitySection
                windSection
                breakSection
                presetsSection
            }
            .padding()
        }
        .frame(height: 420)
        .background(Color(.systemGroupedBackground))
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

    // MARK: - Wind Section

    private var windSection: some View {
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
                    Text("Wind Preset")
                        .foregroundStyle(.secondary)

                    Picker("Preset", selection: $windPreset) {
                        ForEach(WindPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Blow: \(Int(windPreset.minutesToBlowAway)) min • Recover: \(Int(windPreset.minutesToRecover)) min")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Text("Wind Level")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(windLevel.displayName)
                        .foregroundStyle(windLevel.color)
                        .font(.system(.body, weight: .semibold))
                }

                HStack {
                    Text("Is Blown")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isBlownAway ? "Yes" : "No")
                        .foregroundStyle(isBlownAway ? .red : .secondary)
                }
            }
        }
    }

    // MARK: - Break Section

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
                            Text("-\(String(format: "%.1f", activeBreak.windDecreased(for: windPreset))) pts")
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
                presetButton("Calm", color: .green) { applyCalmPreset() }
                presetButton("Rising Wind", color: .yellow) { applyRisingPreset() }
                presetButton("Blob", color: .gray) { applyBlobPreset() }
                presetButton("On Break", color: .blue) { applyBreakPreset() }
                presetButton("Critical", color: .orange) { applyCriticalPreset() }
                presetButton("Blown Away", color: .red) { applyBlownAwayPreset() }
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

    // MARK: - Presets

    private func applyCalmPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 2
            totalDays = 14
            windPoints = 15
            windPreset = .balanced
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyRisingPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Gaming"
            isBlob = false
            currentPhase = 2
            totalDays = 10
            windPoints = 55
            windPreset = .balanced
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyBlobPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Blobby"
            purposeLabel = "Social Media"
            isBlob = true
            totalDays = 1
            windPoints = 25
            windPreset = .gentle
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyBreakPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 2
            totalDays = 8
            windPoints = 65
            windPreset = .balanced
            hasActiveBreak = true
            breakType = .committed
            breakMinutesAgo = 10
            breakDurationMinutes = 30
            isBlownAway = false
        }
    }

    private func applyCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Streaming"
            isBlob = false
            currentPhase = 3
            totalDays = 5
            windPoints = 85
            windPreset = .intense
            hasActiveBreak = false
            isBlownAway = false
        }
    }

    private func applyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Social Media"
            isBlob = false
            currentPhase = 3
            totalDays = 0
            windPoints = 100
            windPreset = .balanced
            hasActiveBreak = false
            isBlownAway = true
        }
    }

    // MARK: - Helpers

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
