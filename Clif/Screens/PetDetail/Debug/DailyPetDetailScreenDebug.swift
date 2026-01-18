#if DEBUG
import SwiftUI

struct DailyPetDetailScreenDebug: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Pet Identity State

    @State private var petName: String = "Fern"
    @State private var purposeLabel: String = "Social Media"
    @State private var essence: Essence = .plant
    @State private var currentPhase: Int = 2
    @State private var totalDays: Int = 12

    // MARK: - Screen Time State

    @State private var todayUsedMinutes: Double = 83
    @State private var dailyLimitMinutes: Double = 180

    // MARK: - Pet State

    @State private var isBlownAway: Bool = false

    // MARK: - Section Expansion

    @State private var isPetSectionExpanded: Bool = true
    @State private var isWeatherSectionExpanded: Bool = true
    @State private var isTimeSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Sheet State

    @State private var showSheet: Bool = false

    // MARK: - Computed Properties

    private var windProgress: CGFloat {
        dailyLimitMinutes > 0 ? CGFloat(todayUsedMinutes / dailyLimitMinutes) : 0
    }

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var mood: Mood {
        Mood(from: windLevel)
    }

    private var evolutionHistory: EvolutionHistory {
        // Build events array for phases reached
        let events: [EvolutionEvent] = (2...currentPhase).map { phase in
            let daysAgo = (currentPhase - phase + 1) * 3
            return EvolutionEvent(
                fromPhase: phase - 1,
                toPhase: phase,
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            )
        }

        return EvolutionHistory(
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            essence: essence,
            events: currentPhase > 1 ? events : [],
            blownAt: isBlownAway ? Date() : nil
        )
    }

    private var evolutionPath: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    private var canEvolve: Bool {
        currentPhase < evolutionPath.maxPhases && !isBlownAway
    }

    private var dailyStats: [DailyUsageStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let petId = UUID()

        return (0..<totalDays).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(totalDays - 1) + dayOffset, to: today)!
            let minutes = Int.random(in: 20...Int(dailyLimitMinutes + 30))
            return DailyUsageStat(petId: petId, date: date, totalMinutes: minutes)
        }
    }

    private var debugPet: DailyPet {
        DailyPet(
            name: petName,
            evolutionHistory: evolutionHistory,
            purpose: purposeLabel.isEmpty ? nil : purposeLabel,
            todayUsedMinutes: Int(todayUsedMinutes),
            dailyLimitMinutes: Int(dailyLimitMinutes),
            dailyStats: dailyStats
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Preview Button
                previewSection
                    .frame(maxHeight: .infinity)

                Divider()

                // Controls Panel
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
            DailyPetDetailScreen(
                pet: debugPet,
                onBlowAway: { print("Blow Away tapped") },
                onReplay: { print("Replay tapped") },
                onDelete: { print("Delete tapped") },
                onLimitedApps: { print("Limited apps tapped") }
            )
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Pet preview card
                VStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text(petName)
                        .font(.title2.weight(.bold))

                    HStack(spacing: 16) {
                        Label("Phase \(currentPhase)/\(evolutionPath.maxPhases)", systemImage: "sparkles")
                        Label("\(totalDays) days", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

                // Open Sheet Button
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
                    .background(.blue, in: Capsule())
                }
            }
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                petIdentitySection
                weatherSection
                screenTimeSection
                presetsSection
            }
            .padding()
        }
        .frame(height: 380)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolution Phase")
                        .foregroundStyle(.secondary)

                    Picker("Phase", selection: $currentPhase) {
                        ForEach(1...evolutionPath.maxPhases, id: \.self) { phase in
                            Text("\(phase)").tag(phase)
                        }
                    }
                    .pickerStyle(.segmented)
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

    // MARK: - Weather Section

    private var weatherSection: some View {
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
                    Text(windLevel.displayName)
                        .foregroundStyle(windLevel.color)
                        .font(.system(.body, weight: .semibold))
                }

                HStack {
                    Text("Wind Progress")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(windProgress * 100))%")
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Pet Mood")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(moodEmoji(for: mood))
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

    // MARK: - Screen Time Section

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
                presetButton("Normal", color: .blue) { applyNormalPreset() }
                presetButton("Evolve Ready", color: .green) { applyEvolveReadyPreset() }
                presetButton("Max Evolution", color: .purple) { applyMaxEvolutionPreset() }
                presetButton("New Pet", color: .mint) { applyNewPetPreset() }
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

    // MARK: - Preset Actions

    private func applyNormalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Fern"
            purposeLabel = "Social Media"
            currentPhase = 2
            totalDays = 12
            todayUsedMinutes = 100  // ~55% = medium zone
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyEvolveReadyPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purposeLabel = "Gaming"
            currentPhase = 2
            totalDays = 7
            todayUsedMinutes = 60  // ~33% = low zone
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyMaxEvolutionPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Elder Oak"
            purposeLabel = "Work Apps"
            currentPhase = 4
            totalDays = 30
            todayUsedMinutes = 0  // 0% = none zone
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyNewPetPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Seedling"
            purposeLabel = ""
            currentPhase = 1
            totalDays = 0
            todayUsedMinutes = 0  // 0% = none zone
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Streaming"
            currentPhase = 3
            totalDays = 5
            todayUsedMinutes = 160  // ~89% = high zone
            dailyLimitMinutes = 180
            isBlownAway = false
        }
    }

    private func applyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Social Media"
            currentPhase = 3
            totalDays = 0
            todayUsedMinutes = 230  // >100% = high zone
            dailyLimitMinutes = 180
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

    private func moodEmoji(for mood: Mood) -> String {
        switch mood {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😢"
        case .blown: return "😵"
        }
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
        DailyPetDetailScreenDebug()
    }
}
#endif
