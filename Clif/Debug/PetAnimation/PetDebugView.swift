#if DEBUG
import SwiftUI

/// Debug view for testing and configuring pet animation parameters (idle + wind + tap effects).
struct PetDebugView: View {
    // Evolution selection
    @State private var selectedEvolutionType: EvolutionTypeOption = .plant
    @State private var plantPhase: Int = 1
    @State private var windLevel: WindLevel = .medium
    @State private var direction: CGFloat = 1.0
    @State private var showCopiedFeedback: Bool = false

    // Panel expansion state (3 phases)
    @State private var panelState: PanelState = .medium

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

    // Speech bubble debug
    @State private var isSpeechBubbleExpanded: Bool = false
    @State private var debugBubblePosition: SpeechBubblePosition? = .right
    @State private var debugSpeechBubbleState = SpeechBubbleState()
    @State private var debugCustomText: String = ""

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

                // Wind lines effect (debug colors: blue=wave, green=sCurve, red=loop)
                WindLinesView(windLevel: windLevel, debugColors: true)

                // Floating island with pet - render appropriate evolution type
                Group {
                    switch selectedEvolutionType {
                    case .blob:
                        DebugFloatingIslandView(
                            screenHeight: geometry.size.height,
                            evolution: BlobEvolution.blob,
                            windLevel: windLevel,
                            debugWindConfig: customWindConfig,
                            windDirection: direction,
                            debugTapType: selectedTapType,
                            debugTapConfig: customTapConfig,
                            debugIdleConfig: currentIdleConfig,
                            debugHapticType: selectedHapticType,
                            debugHapticDuration: hapticDuration,
                            debugHapticIntensity: Float(hapticIntensity),
                            externalTapTime: $tapTime,
                            debugSpeechBubbleState: debugSpeechBubbleState,
                            debugCustomText: debugCustomText
                        )
                    case .plant:
                        DebugFloatingIslandView(
                            screenHeight: geometry.size.height,
                            evolution: PlantEvolution(rawValue: plantPhase) ?? .phase1,
                            windLevel: windLevel,
                            debugWindConfig: customWindConfig,
                            windDirection: direction,
                            debugTapType: selectedTapType,
                            debugTapConfig: customTapConfig,
                            debugIdleConfig: currentIdleConfig,
                            debugHapticType: selectedHapticType,
                            debugHapticDuration: hapticDuration,
                            debugHapticIntensity: Float(hapticIntensity),
                            externalTapTime: $tapTime,
                            debugSpeechBubbleState: debugSpeechBubbleState,
                            debugCustomText: debugCustomText
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Debug controls panel
                debugControlsPanel(
                    screenHeight: geometry.size.height,
                    safeAreaTop: geometry.safeAreaInsets.top
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Debug Controls

    private func debugControlsPanel(screenHeight: CGFloat, safeAreaTop: CGFloat) -> some View {
        // Calculate top offset for fullscreen state (20pt below back chevron)
        let fullscreenTopOffset = safeAreaTop + 44 + 20

        return VStack(spacing: 0) {
            // Top spacer - in fullscreen, fixed height; otherwise flexible
            if panelState == .fullscreen {
                Color.clear.frame(height: fullscreenTopOffset)
            } else {
                Spacer()
            }

            VStack(spacing: 12) {
                // Drag handle - this area handles swipe gestures
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    // Header - entire area is tappable for expand/collapse
                    HStack {
                        Text("Pet Debug")
                            .font(.headline)

                        Spacer()

                        Image(systemName: panelState.chevronIcon)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Button {
                            copyConfig()
                        } label: {
                            Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                        .tint(showCopiedFeedback ? .green : nil)
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
                                    // Swipe down - go to previous state
                                    switch panelState {
                                    case .fullscreen: panelState = .medium
                                    case .medium: panelState = .minimized
                                    case .minimized: break
                                    }
                                } else if value.translation.height < -50 {
                                    // Swipe up - go to next state
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
                    isExpanded: $isIdleExpanded,
                    onReset: resetIdleToDefaults
                ) {
                    idleControlsContent
                }

                Divider()

                // ===== WIND SECTION =====
                collapsibleSection(
                    title: "Wind",
                    isExpanded: $isWindExpanded,
                    onReset: resetWindToDefaults
                ) {
                    windControlsContent
                }

                Divider()

                // ===== TAP SECTION =====
                collapsibleSection(
                    title: "Tap Animation",
                    isExpanded: $isTapExpanded,
                    onReset: resetTapToDefaults
                ) {
                    tapControlsContent
                }

                Divider()

                // ===== SPEECH BUBBLE SECTION =====
                collapsibleSection(
                    title: "Speech Bubble",
                    isExpanded: $isSpeechBubbleExpanded,
                    onReset: resetSpeechBubbleToDefaults
                ) {
                    speechBubbleControlsContent
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: panelState == .fullscreen ? .infinity : 350)
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        onReset: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Title - tappable to expand/collapse
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.wrappedValue.toggle()
                    }
                }

                // Reset button - separate, larger tap target
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onReset()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            if isExpanded.wrappedValue {
                content()
            }
        }
    }

    // MARK: - Reset Functions

    private func resetIdleToDefaults() {
        let defaults = IdleConfig.default
        idleEnabled = defaults.enabled
        idleAmplitude = defaults.amplitude
        idleFrequency = defaults.frequency
        idleFocusStart = defaults.focusStart
        idleFocusEnd = defaults.focusEnd
    }

    private func resetWindToDefaults() {
        useCustomConfig = false
        windLevel = .medium
        direction = 1.0
        customIntensity = 0.5
        customBendCurve = 2.0
        customSwayAmount = 0.3
        customRotationAmount = 0.5
    }

    private func resetTapToDefaults() {
        useCustomTapConfig = false
        selectedTapType = .wiggle
        selectedHapticType = .impactLight
        hapticDuration = 0.3
        hapticIntensity = 0.8
        let defaults = TapConfig.default(for: .wiggle)
        customTapIntensity = defaults.intensity
        customTapDecayRate = defaults.decayRate
        customTapFrequency = defaults.frequency
    }

    private func resetSpeechBubbleToDefaults() {
        debugBubblePosition = .right
        debugCustomText = ""
        debugSpeechBubbleState.hide()
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
                Text("\u{2190} Left").tag(-1.0 as CGFloat)
                Text("\u{2192} Right").tag(1.0 as CGFloat)
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

    // MARK: - Speech Bubble Controls

    @ViewBuilder
    private var speechBubbleControlsContent: some View {
        // Position picker
        Picker("Position", selection: $debugBubblePosition) {
            Text("Left").tag(SpeechBubblePosition.left as SpeechBubblePosition?)
            Text("Right").tag(SpeechBubblePosition.right as SpeechBubblePosition?)
        }
        .pickerStyle(.segmented)

        // Custom text field
        TextField("Text (empty = emoji)", text: $debugCustomText)
            .textFieldStyle(.roundedBorder)

        // Manual trigger button
        Button {
            triggerDebugBubble()
        } label: {
            HStack {
                Image(systemName: "bubble.left.fill")
                Text("Show Speech Bubble")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private func triggerDebugBubble() {
        debugSpeechBubbleState.forceShow(
            mood: Mood(from: windLevel),
            source: .random,
            position: debugBubblePosition ?? .right,
            customText: debugCustomText.isEmpty ? nil : debugCustomText
        )
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
