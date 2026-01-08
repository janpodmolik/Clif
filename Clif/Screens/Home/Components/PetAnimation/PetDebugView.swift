#if DEBUG
import SwiftUI

/// Debug view for testing and configuring pet animation parameters (idle + wind + tap effects).
struct PetDebugView: View {
    // Evolution selection
    @State private var selectedEvolutionType: EvolutionTypeOption = .plant
    @State private var plantPhase: Int = 1
    @State private var windLevel: WindLevel = .medium
    @State private var direction: CGFloat = 1.0
    @State private var showControls: Bool = true
    @State private var showCopiedFeedback: Bool = false

    // Section collapse states
    @State private var isIdleExpanded: Bool = false
    @State private var isWindExpanded: Bool = true
    @State private var isTapExpanded: Bool = false

    // Custom wind override mode
    @State private var useCustomConfig: Bool = false
    @State private var customIntensity: CGFloat = 0.5
    @State private var customBendCurve: CGFloat = 2.0
    @State private var customSwayAmount: CGFloat = 0.3
    @State private var customRotationAmount: CGFloat = 0.5

    // Idle animation
    @State private var idleEnabled: Bool = true
    @State private var idleAmplitude: CGFloat = IdleConfig.default.amplitude
    @State private var idleFrequency: CGFloat = IdleConfig.default.frequency
    @State private var idleFocusStart: CGFloat = IdleConfig.default.focusStart
    @State private var idleFocusEnd: CGFloat = IdleConfig.default.focusEnd

    // Tap animation
    @State private var tapTime: TimeInterval = -1
    @State private var selectedTapType: TapAnimationType = .wiggle
    @State private var selectedHapticType: HapticType = .impactLight
    @State private var hapticDuration: Double = 0.3
    @State private var hapticIntensity: Double = 0.8
    @State private var useCustomTapConfig: Bool = false
    @State private var customTapIntensity: CGFloat = TapConfig.default(for: .wiggle).intensity
    @State private var customTapDecayRate: CGFloat = TapConfig.default(for: .wiggle).decayRate
    @State private var customTapFrequency: CGFloat = TapConfig.default(for: .wiggle).frequency

    enum EvolutionTypeOption: String, CaseIterable {
        case blob = "Blob"
        case plant = "Plant"
    }

    private var customWindConfig: WindConfig? {
        guard useCustomConfig else { return nil }
        return WindConfig(
            intensity: customIntensity,
            bendCurve: customBendCurve,
            swayAmount: customSwayAmount,
            rotationAmount: customRotationAmount
        )
    }

    private var customTapConfig: TapConfig? {
        guard useCustomTapConfig else { return nil }
        return TapConfig(
            intensity: customTapIntensity,
            decayRate: customTapDecayRate,
            frequency: customTapFrequency
        )
    }

    private var currentIdleConfig: IdleConfig {
        IdleConfig(
            enabled: idleEnabled,
            amplitude: idleAmplitude,
            frequency: idleFrequency,
            focusStart: idleFocusStart,
            focusEnd: idleFocusEnd
        )
    }

    private var moodColor: Color {
        switch Mood(from: windLevel) {
        case .happy: return .green
        case .neutral: return .yellow
        case .sad: return .red
        }
    }

    /// Current evolution name for export
    private var currentEvolutionName: String {
        switch selectedEvolutionType {
        case .blob:
            return "BlobEvolution.blob"
        case .plant:
            return "PlantEvolution.phase\(plantPhase)"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.blue.opacity(0.3)

                // Cliff with pet - render appropriate evolution type
                Group {
                    switch selectedEvolutionType {
                    case .blob:
                        CliffView(
                            screenHeight: geometry.size.height,
                            evolution: BlobEvolution.blob,
                            windLevel: windLevel,
                            debugWindConfig: customWindConfig,
                            windDirection: direction,
                            debugTapType: selectedTapType,
                            debugTapConfig: customTapConfig,
                            debugIdleConfig: currentIdleConfig,
                            debugHapticStyle: selectedHapticType.impactStyle,
                            externalTapTime: $tapTime
                        )
                    case .plant:
                        CliffView(
                            screenHeight: geometry.size.height,
                            evolution: PlantEvolution(rawValue: plantPhase) ?? .phase1,
                            windLevel: windLevel,
                            debugWindConfig: customWindConfig,
                            windDirection: direction,
                            debugTapType: selectedTapType,
                            debugTapConfig: customTapConfig,
                            debugIdleConfig: currentIdleConfig,
                            debugHapticStyle: selectedHapticType.impactStyle,
                            externalTapTime: $tapTime
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Debug controls panel
                debugControlsPanel
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Debug Controls

    private var debugControlsPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Drag handle indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                // Header with collapse toggle and copy button
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Pet Debug")
                                .font(.headline)
                            Spacer()
                            Image(systemName: showControls ? "chevron.down" : "chevron.up")
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        copyConfig()
                    } label: {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(showCopiedFeedback ? .green : nil)
                }

                if showControls {
                    controlsContent
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        // Swipe down to minimize
                        if value.translation.height > 50 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls = false
                            }
                        }
                        // Swipe up to expand
                        else if value.translation.height < -50 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls = true
                            }
                        }
                    }
            )
        }
    }

    @ViewBuilder
    private var controlsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Evolution type selector
                Picker("Evolution", selection: $selectedEvolutionType) {
                    ForEach(EvolutionTypeOption.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                // Phase selector (only for plant)
                if selectedEvolutionType == .plant {
                    HStack {
                        Text("Phase: \(plantPhase)")
                        Spacer()
                        Stepper("", value: $plantPhase, in: 1...4)
                            .labelsHidden()
                    }
                }

                Divider()

                // ===== IDLE SECTION =====
                collapsibleSection(
                    title: "Idle (Breathe)",
                    isExpanded: $isIdleExpanded
                ) {
                    idleControlsContent
                }

                Divider()

                // ===== WIND SECTION =====
                collapsibleSection(
                    title: "Wind",
                    isExpanded: $isWindExpanded
                ) {
                    windControlsContent
                }

                Divider()

                // ===== TAP SECTION =====
                collapsibleSection(
                    title: "Tap Animation",
                    isExpanded: $isTapExpanded
                ) {
                    tapControlsContent
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 350)
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
            }
        }
    }

    // MARK: - Idle Controls

    @ViewBuilder
    private var idleControlsContent: some View {
        Toggle("Idle Enabled", isOn: $idleEnabled)

        if idleEnabled {
            HStack {
                Text("Amplitude: \(idleAmplitude, specifier: "%.3f")")
                    .font(.caption)
                    .frame(width: 130, alignment: .leading)
                Slider(value: $idleAmplitude, in: 0...0.1)
            }

            HStack {
                Text("Frequency: \(idleFrequency, specifier: "%.2f") Hz")
                    .font(.caption)
                    .frame(width: 130, alignment: .leading)
                Slider(value: $idleFrequency, in: 0.1...1.0)
            }

            Text("Focus Zone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            HStack {
                Text("Start: \(idleFocusStart, specifier: "%.2f")")
                    .font(.caption)
                    .frame(width: 130, alignment: .leading)
                Slider(value: $idleFocusStart, in: 0...1)
            }

            HStack {
                Text("End: \(idleFocusEnd, specifier: "%.2f")")
                    .font(.caption)
                    .frame(width: 130, alignment: .leading)
                Slider(value: $idleFocusEnd, in: 0...1)
            }

            Text("0 = bottom, 1 = top. Full effect below Start, fades to End.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Wind Controls

    @ViewBuilder
    private var windControlsContent: some View {
        // Wind level selector with mood indicator
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Wind Level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Mood: \(Mood(from: windLevel).rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(moodColor.opacity(0.2))
                    .cornerRadius(4)
            }
            Picker("Wind Level", selection: $windLevel) {
                ForEach(WindLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }

        // Wind direction
        HStack {
            Text("Direction")
            Picker("", selection: $direction) {
                Text("← Left").tag(-1.0 as CGFloat)
                Text("→ Right").tag(1.0 as CGFloat)
            }
            .pickerStyle(.segmented)
        }

        // Custom wind config toggle
        Toggle("Custom Wind Config", isOn: $useCustomConfig)

        if useCustomConfig {
            customWindControls
        }
    }

    @ViewBuilder
    private var customWindControls: some View {
        HStack {
            Text("Intensity: \(customIntensity, specifier: "%.2f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customIntensity, in: 0...2)
        }

        HStack {
            Text("Bend: \(customBendCurve, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customBendCurve, in: 0.5...4.0)
        }

        HStack {
            Text("Sway: \(customSwayAmount, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customSwayAmount, in: 0...2)
        }

        HStack {
            Text("Rotation: \(customRotationAmount, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customRotationAmount, in: 0...2)
        }
    }

    // MARK: - Tap Controls

    @ViewBuilder
    private var tapControlsContent: some View {
        // Tap type picker
        VStack(alignment: .leading, spacing: 4) {
            Text("Animation Type")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Type", selection: $selectedTapType) {
                ForEach(TapAnimationType.allCases.filter { $0 != .none }, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }

        // Haptic type picker
        VStack(alignment: .leading, spacing: 4) {
            Text("Haptic Feedback")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Haptic", selection: $selectedHapticType) {
                ForEach(HapticType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            Text(selectedHapticType.description)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Duration & intensity sliders for custom haptics
            if selectedHapticType.supportsDuration {
                HStack {
                    Text("Duration: \(hapticDuration, specifier: "%.2f")s")
                        .font(.caption)
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $hapticDuration, in: 0.1...1.0)
                }

                HStack {
                    Text("Intensity: \(hapticIntensity, specifier: "%.1f")")
                        .font(.caption)
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $hapticIntensity, in: 0.1...1.0)
                }
            }
        }

        // Trigger button
        Button {
            triggerTapAnimation()
        } label: {
            HStack {
                Image(systemName: "hand.tap.fill")
                Text("Trigger \(selectedTapType.displayName)")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        // Custom tap config toggle
        Toggle("Custom Tap Config", isOn: $useCustomTapConfig)

        if useCustomTapConfig {
            customTapControls
        }
    }

    private var intensityRange: ClosedRange<CGFloat> {
        switch selectedTapType {
        case .squeeze:
            return 0...0.5  // Percentage-based (0-50%)
        default:
            return 0...50   // Pixel-based
        }
    }

    @ViewBuilder
    private var customTapControls: some View {
        HStack {
            Text("Intensity: \(customTapIntensity, specifier: "%.2f")")
                .frame(width: 130, alignment: .leading)
            Slider(value: $customTapIntensity, in: intensityRange)
        }

        HStack {
            Text("Decay: \(customTapDecayRate, specifier: "%.1f")")
                .frame(width: 130, alignment: .leading)
            Slider(value: $customTapDecayRate, in: 1...15)
        }

        HStack {
            Text("Frequency: \(customTapFrequency, specifier: "%.0f")")
                .frame(width: 130, alignment: .leading)
            Slider(value: $customTapFrequency, in: 5...60)
        }

        // Reset all values to defaults when switching animation types
        .onChange(of: selectedTapType) {
            let defaults = TapConfig.default(for: selectedTapType)
            customTapIntensity = defaults.intensity
            customTapDecayRate = defaults.decayRate
            customTapFrequency = defaults.frequency
        }
    }

    // MARK: - Actions

    private func triggerTapAnimation() {
        tapTime = Date().timeIntervalSinceReferenceDate

        // Haptic feedback
        selectedHapticType.trigger(
            duration: hapticDuration,
            intensity: Float(hapticIntensity)
        )
    }

    private func copyConfig() {
        let currentEvolution: any EvolutionType = selectedEvolutionType == .blob
            ? BlobEvolution.blob
            : PlantEvolution(rawValue: plantPhase) ?? .phase1

        let wiggleConfig = useCustomTapConfig && selectedTapType == .wiggle
            ? customTapConfig!
            : AnimationConfigProvider.tapConfig(for: currentEvolution, type: .wiggle)
        let squeezeConfig = useCustomTapConfig && selectedTapType == .squeeze
            ? customTapConfig!
            : AnimationConfigProvider.tapConfig(for: currentEvolution, type: .squeeze)
        let jiggleConfig = useCustomTapConfig && selectedTapType == .jiggle
            ? customTapConfig!
            : AnimationConfigProvider.tapConfig(for: currentEvolution, type: .jiggle)

        let windConfig = customWindConfig ?? WindConfig(
            intensity: 0.5,
            bendCurve: 2.0,
            swayAmount: 0.3,
            rotationAmount: 0.5
        )

        let export = """
        === Evolution Config Export ===
        Evolution: \(currentEvolutionName)

        Idle Config:
          enabled: \(idleEnabled)
          amplitude: \(String(format: "%.3f", idleAmplitude))
          frequency: \(String(format: "%.2f", idleFrequency))
          focusStart: \(String(format: "%.2f", idleFocusStart))
          focusEnd: \(String(format: "%.2f", idleFocusEnd))

        Tap Config (wiggle):
          intensity: \(String(format: "%.1f", wiggleConfig.intensity))
          decayRate: \(String(format: "%.1f", wiggleConfig.decayRate))
          frequency: \(String(format: "%.1f", wiggleConfig.frequency))

        Tap Config (squeeze):
          intensity: \(String(format: "%.3f", squeezeConfig.intensity))
          decayRate: \(String(format: "%.1f", squeezeConfig.decayRate))
          frequency: \(String(format: "%.1f", squeezeConfig.frequency))

        Tap Config (jiggle):
          intensity: \(String(format: "%.1f", jiggleConfig.intensity))
          decayRate: \(String(format: "%.1f", jiggleConfig.decayRate))
          frequency: \(String(format: "%.1f", jiggleConfig.frequency))

        Wind Config (current - \(windLevel.displayName)):
          intensity: \(String(format: "%.2f", windConfig.intensity))
          bendCurve: \(String(format: "%.1f", windConfig.bendCurve))
          swayAmount: \(String(format: "%.1f", windConfig.swayAmount))
          rotationAmount: \(String(format: "%.1f", windConfig.rotationAmount))
        """

        UIPasteboard.general.string = export

        // Show feedback
        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

#Preview("Pet Debug") {
    PetDebugView()
}
#endif
