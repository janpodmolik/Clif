#if DEBUG
import SwiftUI

struct HomeCardDebugView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Pet Identity State

    @State private var petName: String = "Fern"
    @State private var purposeLabel: String = "Social Media"
    @State private var evolutionStage: Int = 2
    private let maxEvolutionStage = 4

    // MARK: - Screen Time State

    @State private var usedMinutes: Double = 83
    @State private var limitMinutes: Double = 180
    @State private var streakCount: Int = 12

    // MARK: - Button Visibility State

    @State private var showEvolveButton: Bool = false
    @State private var daysUntilEvolution: Int = 1
    @State private var showDetailButton: Bool = true
    @State private var isBlownAway: Bool = false

    // MARK: - Section Expansion

    @State private var isPetSectionExpanded: Bool = true
    @State private var isTimeSectionExpanded: Bool = true
    @State private var isButtonsSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Computed Properties

    private var progress: Double {
        guard limitMinutes > 0 else { return 0 }
        return usedMinutes / limitMinutes
    }

    private var currentMood: Mood {
        if isBlownAway {
            return .blown
        }
        switch progress {
        case 0..<0.5: return .happy
        case 0.5..<0.8: return .neutral
        default: return .sad
        }
    }

    private var usedTimeText: String {
        formatTime(minutes: Int(usedMinutes))
    }

    private var dailyLimitText: String {
        formatTime(minutes: Int(limitMinutes))
    }

    private var isSaveEnabled: Bool {
        evolutionStage >= 2
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Live Preview
                previewSection
                    .frame(maxHeight: .infinity)

                Divider()

                // Controls Panel
                controlsPanel
            }
        }
        .navigationTitle("HomeCard Debug")
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
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            // Simulated background
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HomeCardContentView(
                streakCount: streakCount,
                usedTimeText: usedTimeText,
                dailyLimitText: dailyLimitText,
                progress: progress,
                petName: petName,
                evolutionStage: evolutionStage,
                maxEvolutionStage: maxEvolutionStage,
                mood: currentMood,
                purposeLabel: purposeLabel.isEmpty ? nil : purposeLabel,
                isEvolutionAvailable: showEvolveButton,
                daysUntilEvolution: showEvolveButton ? nil : daysUntilEvolution,
                isSaveEnabled: isSaveEnabled,
                showDetailButton: showDetailButton,
                isBlownAway: isBlownAway,
                onDetailTapped: { print("Detail tapped") },
                onEvolveTapped: { print("Evolve tapped") },
                onSavePetTapped: { print("Finish tapped") },
                onBlowAwayTapped: { print("Blow Away tapped") },
                onReplayTapped: { print("Replay tapped") },
                onDeleteTapped: { print("Delete tapped") }
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding(20)
            .frame(maxWidth: 360)
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                petIdentitySection
                screenTimeSection
                buttonsSection
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
                // Pet Name
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Pet name", text: $petName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                // Purpose Label
                HStack {
                    Text("Purpose")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. Social Media", text: $purposeLabel)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                // Evolution Stage
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolution Stage")
                        .foregroundStyle(.secondary)

                    Picker("Stage", selection: $evolutionStage) {
                        ForEach(1...maxEvolutionStage, id: \.self) { stage in
                            Text("\(stage)").tag(stage)
                        }
                    }
                    .pickerStyle(.segmented)
                }
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
                // Used minutes slider
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

                // Limit minutes slider
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

                // Streak stepper
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

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        collapsibleSection(
            title: "Buttons",
            systemImage: "rectangle.on.rectangle",
            isExpanded: $isButtonsSectionExpanded
        ) {
            VStack(spacing: 12) {
                Toggle("Blown Away State", isOn: $isBlownAway)

                if !isBlownAway {
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

                    HStack {
                        Text("Blow Away Button")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Always visible")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else {
                    HStack {
                        Text("Replay Button")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Visible when blown away")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    HStack {
                        Text("Delete Button")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Visible when blown away")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Toggle("Show Detail Button", isOn: $showDetailButton)
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
            evolutionStage = 2
            usedMinutes = 85
            limitMinutes = 180
            streakCount = 12
            showEvolveButton = false
            showDetailButton = true
            isBlownAway = false
        }
    }

    private func applyEvolveReadyPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purposeLabel = "Gaming"
            evolutionStage = 2
            usedMinutes = 60
            limitMinutes = 180
            streakCount = 7
            showEvolveButton = true
            showDetailButton = true
            isBlownAway = false
        }
    }

    private func applyMaxEvolutionPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Elder Oak"
            purposeLabel = "Work Apps"
            evolutionStage = 4
            usedMinutes = 45
            limitMinutes = 180
            streakCount = 30
            showEvolveButton = false
            showDetailButton = true
            isBlownAway = false
        }
    }

    private func applyNewPetPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Seedling"
            purposeLabel = ""
            evolutionStage = 1
            usedMinutes = 0
            limitMinutes = 180
            streakCount = 0
            showEvolveButton = false
            showDetailButton = true
            isBlownAway = false
        }
    }

    private func applyCriticalPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Streaming"
            evolutionStage = 3
            usedMinutes = 170
            limitMinutes = 180
            streakCount = 5
            showEvolveButton = false
            showDetailButton = true
            isBlownAway = false
        }
    }

    private func applyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Willow"
            purposeLabel = "Social Media"
            evolutionStage = 3
            usedMinutes = 230
            limitMinutes = 180
            streakCount = 0
            showEvolveButton = false
            showDetailButton = true
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
        HomeCardDebugView()
    }
}
#endif
