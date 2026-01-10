#if DEBUG
import SwiftUI

/// Debug view for testing and configuring pet animation parameters (idle + wind + tap effects).
struct PetDebugView: View {
    // Evolution selection
    @State private var selectedEvolutionType: EvolutionTypeOption = .blob
    @State private var plantPhase: Int = 1
    @State private var windLevel: WindLevel = .medium
    @State private var direction: CGFloat = 1.0
    @State private var showCopiedFeedback: Bool = false
    @State private var windIntensityScale: CGFloat = 1.0

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

    // Blow away debug
    @State private var isBlowAwayExpanded: Bool = false
    @State private var blowAwayOffsetX: CGFloat = 0
    @State private var blowAwayRotation: CGFloat = 0
    @State private var blowAwayDuration: Double = 0.8
    @State private var blowAwayRotationAmount: CGFloat = 25
    @State private var isBlowingAway: Bool = false
    @State private var windLinesBurstActive: Bool = false

    /// Shared wind rhythm for synchronized wind effects between pet and wind lines
    @State private var debugWindRhythm = WindRhythm()

    // Evolution transition debug
    @State private var isEvolutionExpanded: Bool = false
    @State private var transitionDuration: Double = EvolutionTransitionConfig.defaultDuration
    @State private var isTransitioning: Bool = false
    @State private var useCustomTransitionConfig: Bool = false
    @State private var customGlowIntensity: CGFloat = 2.5
    @State private var showEvolutionTransition: Bool = false
    @State private var transitionToPhase: Int = 2
    @State private var evolutionTransitionKey: UUID = UUID()

    // Particle effect debug
    @State private var particlesEnabled: Bool = true
    @State private var particleCount: Int = 80

    private let windCalmDuration: TimeInterval = 1.1
    private let windRestoreDuration: TimeInterval = 0.8

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
        case .sad, .blown: return .red
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
                WindLinesView(
                    windLevel: windLinesBurstActive ? .high : windLevel,
                    direction: direction,
                    debugColors: true,
                    windAreaTop: 0.25,
                    windAreaBottom: 0.50,
                    intensityScale: windIntensityScale,
                    overrideConfig: windLinesBurstActive ? .burst : nil,
                    windRhythm: windLinesBurstActive ? nil : debugWindRhythm
                )

                // Floating island with pet - render appropriate evolution type
                ZStack {
                    Group {
                        switch selectedEvolutionType {
                        case .blob:
                            DebugFloatingIslandView(
                                screenHeight: geometry.size.height,
                                screenWidth: geometry.size.width,
                                evolution: BlobEvolution.blob,
                                windLevel: windLevel,
                                debugWindConfig: customWindConfig,
                                windDirection: direction,
                                windIntensityScale: windIntensityScale,
                                windRhythm: debugWindRhythm,
                                debugTapType: selectedTapType,
                                debugTapConfig: customTapConfig,
                                debugIdleConfig: currentIdleConfig,
                                debugHapticType: selectedHapticType,
                                debugHapticDuration: hapticDuration,
                                debugHapticIntensity: Float(hapticIntensity),
                                externalTapTime: $tapTime,
                                debugSpeechBubbleState: debugSpeechBubbleState,
                                debugCustomText: debugCustomText,
                                blowAwayOffsetX: blowAwayOffsetX,
                                blowAwayRotation: blowAwayRotation
                            )
                        case .plant:
                            DebugFloatingIslandView(
                                screenHeight: geometry.size.height,
                                screenWidth: geometry.size.width,
                                evolution: PlantEvolution(rawValue: plantPhase) ?? .phase1,
                                windLevel: windLevel,
                                debugWindConfig: customWindConfig,
                                windDirection: direction,
                                windIntensityScale: windIntensityScale,
                                windRhythm: debugWindRhythm,
                                debugTapType: selectedTapType,
                                debugTapConfig: customTapConfig,
                                debugIdleConfig: currentIdleConfig,
                                debugHapticType: selectedHapticType,
                                debugHapticDuration: hapticDuration,
                                debugHapticIntensity: Float(hapticIntensity),
                                externalTapTime: $tapTime,
                                debugSpeechBubbleState: debugSpeechBubbleState,
                                debugCustomText: debugCustomText,
                                blowAwayOffsetX: blowAwayOffsetX,
                                blowAwayRotation: blowAwayRotation,
                                evolutionTransitionView: showEvolutionTransition ? AnyView(
                                    EvolutionTransitionView(
                                        isActive: true,
                                        config: currentTransitionConfig,
                                        particleConfig: currentParticleConfig,
                                        oldAssetName: PlantEvolution(rawValue: plantPhase)?.assetName(for: windLevel) ?? "evolutions/plant/happy/1",
                                        newAssetName: PlantEvolution(rawValue: transitionToPhase)?.assetName(for: windLevel) ?? "evolutions/plant/happy/2",
                                        oldScale: (PlantEvolution(rawValue: plantPhase) ?? .phase1).displayScale,
                                        newScale: (PlantEvolution(rawValue: transitionToPhase) ?? .phase2).displayScale,
                                        onComplete: {
                                            // Hide transition FIRST to prevent glitch from syncTransitionPhases
                                            showEvolutionTransition = false
                                            isTransitioning = false
                                            // Then update phase (this triggers syncTransitionPhases via onChange)
                                            plantPhase = transitionToPhase
                                            restoreWindAfterTransition()
                                        }
                                    )
                                    .id(evolutionTransitionKey)
                                ) : nil
                            )
                        }
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
        .onAppear {
            syncTransitionPhases(currentPhase: plantPhase)
            debugWindRhythm.start()
        }
        .onDisappear {
            debugWindRhythm.stop()
        }
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
        ScrollViewReader { scrollProxy in
        ScrollView {
            VStack(spacing: 12) {
                // Evolution type selector
                DebugSegmentedPicker(
                    EvolutionTypeOption.allCases.map { $0 },
                    selection: $selectedEvolutionType,
                    label: { $0.rawValue }
                )

                // Phase selector (only for plant)
                if selectedEvolutionType == .plant {
                    HStack {
                        Text("Phase: \(plantPhase)")
                        Spacer()
                        Stepper("", value: $plantPhase, in: 1...4)
                            .labelsHidden()
                            .onChange(of: plantPhase) { _, newPhase in
                                syncTransitionPhases(currentPhase: newPhase)
                            }
                    }
                }

                Divider()

                // ===== IDLE SECTION =====
                collapsibleSection(
                    title: "Idle (Breathe)",
                    isExpanded: $isIdleExpanded,
                    onReset: resetIdleToDefaults,
                    sectionId: "idle",
                    scrollProxy: scrollProxy
                ) {
                    idleControlsContent
                }

                Divider()

                // ===== WIND SECTION =====
                collapsibleSection(
                    title: "Wind",
                    isExpanded: $isWindExpanded,
                    onReset: resetWindToDefaults,
                    sectionId: "wind",
                    scrollProxy: scrollProxy
                ) {
                    windControlsContent
                }

                Divider()

                // ===== TAP SECTION =====
                collapsibleSection(
                    title: "Tap Animation",
                    isExpanded: $isTapExpanded,
                    onReset: resetTapToDefaults,
                    sectionId: "tap",
                    scrollProxy: scrollProxy
                ) {
                    tapControlsContent
                }

                Divider()

                // ===== SPEECH BUBBLE SECTION =====
                collapsibleSection(
                    title: "Speech Bubble",
                    isExpanded: $isSpeechBubbleExpanded,
                    onReset: resetSpeechBubbleToDefaults,
                    sectionId: "speechBubble",
                    scrollProxy: scrollProxy
                ) {
                    speechBubbleControlsContent
                }

                Divider()

                // ===== BLOW AWAY SECTION =====
                collapsibleSection(
                    title: "Blow Away",
                    isExpanded: $isBlowAwayExpanded,
                    onReset: resetBlowAwayToDefaults,
                    sectionId: "blowAway",
                    scrollProxy: scrollProxy
                ) {
                    blowAwayControlsContent
                }

                Divider()

                // ===== EVOLUTION TRANSITION SECTION =====
                collapsibleSection(
                    title: "Evolution Transition",
                    isExpanded: $isEvolutionExpanded,
                    onReset: resetEvolutionToDefaults,
                    sectionId: "evolution",
                    scrollProxy: scrollProxy
                ) {
                    evolutionTransitionControlsContent
                }
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
        sectionId: String,
        scrollProxy: ScrollViewProxy,
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
                    let willExpand = !isExpanded.wrappedValue
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.wrappedValue.toggle()
                    }
                    if willExpand {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scrollProxy.scrollTo(sectionId, anchor: .top)
                            }
                        }
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
        .id(sectionId)
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
        windIntensityScale = 1.0
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

    private func resetBlowAwayToDefaults() {
        blowAwayDuration = 0.8
        blowAwayRotationAmount = 25
        blowAwayOffsetX = 0
        blowAwayRotation = 0
        isBlowingAway = false
        windLinesBurstActive = false
    }

    private func resetEvolutionToDefaults() {
        transitionDuration = EvolutionTransitionConfig.defaultDuration
        useCustomTransitionConfig = false
        customGlowIntensity = 2.5
        isTransitioning = false
        showEvolutionTransition = false
        windIntensityScale = 1.0
        particlesEnabled = true
        particleCount = 80
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
            DebugSegmentedPicker(
                WindLevel.allCases.map { $0 },
                selection: $windLevel,
                label: { $0.displayName }
            )
        }

        // Wind direction
        DebugSegmentedPicker(
            [-1.0, 1.0],
            selection: $direction,
            label: { $0 < 0 ? "\u{2190} Left" : "\u{2192} Right" }
        )

        // Gust intensity indicator (from shared rhythm)
        HStack {
            Text("Gust Intensity")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            // Progress bar showing current gust intensity
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geo.size.width * debugWindRhythm.gustIntensity)
                }
            }
            .frame(width: 100, height: 8)
            Text("\(debugWindRhythm.gustIntensity, specifier: "%.2f")")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
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
            Slider(value: $customSwayAmount, in: 0...15)
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

            DebugSegmentedPicker(
                TapAnimationType.allCases.filter { $0 != .none },
                selection: $selectedTapType,
                label: { $0.displayName }
            )
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
        case .squeeze, .bounce:
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
        DebugSegmentedPicker(
            [SpeechBubblePosition.left, SpeechBubblePosition.right],
            selection: Binding(
                get: { debugBubblePosition ?? .right },
                set: { debugBubblePosition = $0 }
            ),
            label: { $0 == .left ? "Left" : "Right" }
        )

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

    // MARK: - Blow Away Controls

    @ViewBuilder
    private var blowAwayControlsContent: some View {
        // Duration slider
        HStack {
            Text("Duration: \(blowAwayDuration, specifier: "%.2f")s")
                .font(.caption)
                .frame(width: 130, alignment: .leading)
            Slider(value: $blowAwayDuration, in: 0.3...2.0)
        }

        // Rotation slider
        HStack {
            Text("Rotation: \(blowAwayRotationAmount, specifier: "%.0f")\u{00B0}")
                .font(.caption)
                .frame(width: 130, alignment: .leading)
            Slider(value: $blowAwayRotationAmount, in: 0...45)
        }

        // Blow Away button
        Button {
            triggerBlowAway()
        } label: {
            HStack {
                Image(systemName: "wind")
                Text("Blow Away")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .disabled(isBlowingAway)

        // Reset button (visible when pet is off screen)
        if isBlowingAway {
            Button {
                resetBlowAwayPosition()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Position")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }

        // Status indicator
        if windLinesBurstActive {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Wind burst active...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func triggerBlowAway() {
        // Start wind burst immediately
        windLinesBurstActive = true

        // Animate pet off screen with slight delay (wind catches it)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isBlowingAway = true
            withAnimation(.easeIn(duration: blowAwayDuration)) {
                // Offset: screen width + margin in wind direction
                blowAwayOffsetX = direction * (UIScreen.main.bounds.width + 150)
                // Rotation downward in wind direction
                blowAwayRotation = direction * blowAwayRotationAmount
            }
        }

        // Stop wind burst after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + blowAwayDuration + 0.3) {
            windLinesBurstActive = false
        }
    }

    private func resetBlowAwayPosition() {
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            blowAwayOffsetX = 0
            blowAwayRotation = 0
        }
        isBlowingAway = false
    }

    private func triggerDebugBubble() {
        debugSpeechBubbleState.forceShow(
            mood: Mood(from: windLevel),
            source: .random,
            position: debugBubblePosition ?? .right,
            customText: debugCustomText.isEmpty ? nil : debugCustomText
        )
    }

    // MARK: - Evolution Transition Controls

    @ViewBuilder
    private var evolutionTransitionControlsContent: some View {
        // Only available for Plant evolution
        if selectedEvolutionType != .plant {
            Text("Evolution transition only available for Plant")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            // From/To phase pickers
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DebugSegmentedPicker(
                        [1, 2, 3, 4],
                        selection: $plantPhase,
                        label: { "\($0)" }
                    )
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("To Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DebugSegmentedPicker(
                        [1, 2, 3, 4],
                        selection: $transitionToPhase,
                        label: { "\($0)" }
                    )
                }
            }

            // Duration slider
            HStack {
                Text("Duration: \(transitionDuration, specifier: "%.1f")s")
                    .font(.caption)
                    .frame(width: 130, alignment: .leading)
                Slider(value: $transitionDuration, in: 0.5...4.0)
            }

            // Trigger button
            Button {
                triggerEvolutionTransition()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Trigger Evolution")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isTransitioning || plantPhase == transitionToPhase)

            if plantPhase == transitionToPhase {
                Text("Select different From/To phases")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            // Custom config toggle
            Toggle("Custom Config", isOn: $useCustomTransitionConfig)

            if useCustomTransitionConfig {
                HStack {
                    Text("Glow Intensity: \(customGlowIntensity, specifier: "%.1f")")
                        .font(.caption)
                        .frame(width: 130, alignment: .leading)
                    Slider(value: $customGlowIntensity, in: 1.0...4.0)
                }
            }

            Divider()

            // Particle Effect Controls
            Toggle("Particles", isOn: $particlesEnabled)

            if particlesEnabled {
                // Particle count slider
                HStack {
                    Text("Count: \(particleCount)")
                        .font(.caption)
                        .frame(width: 100, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { Double(particleCount) },
                            set: { particleCount = Int($0) }
                        ),
                        in: 20...300,
                        step: 20
                    )
                }
            }

            // Status indicator
            if isTransitioning {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Transition in progress...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func triggerEvolutionTransition() {
        guard selectedEvolutionType == .plant else { return }
        guard plantPhase != transitionToPhase else { return }
        guard !isTransitioning else { return }

        evolutionTransitionKey = UUID()
        isTransitioning = true
        calmWindThenEvolve()
    }

    private func calmWindThenEvolve() {
        let shouldCalm = windIntensityScale > 0.01

        if shouldCalm {
            withAnimation(.easeOut(duration: windCalmDuration)) {
                windIntensityScale = 0
            }
        }

        let delay = shouldCalm ? windCalmDuration : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isTransitioning {
                showEvolutionTransition = true
            }
        }
    }

    private func restoreWindAfterTransition() {
        withAnimation(.easeIn(duration: windRestoreDuration)) {
            windIntensityScale = 1.0
        }
    }

    private func syncTransitionPhases(currentPhase: Int) {
        if transitionToPhase == currentPhase {
            transitionToPhase = min(currentPhase + 1, 4)
        }
    }

    private var currentTransitionConfig: EvolutionTransitionConfig {
        var config = EvolutionTransitionConfig.default
        config.duration = transitionDuration

        if useCustomTransitionConfig {
            config.glowPeakIntensity = customGlowIntensity
        }

        return config
    }

    private var currentParticleConfig: EvolutionParticleConfig {
        var config = EvolutionParticleConfig.default
        config.enabled = particlesEnabled
        config.particleCount = particleCount
        return config
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
        let bounceConfig = useCustomTapConfig && selectedTapType == .bounce
            ? customTapConfig!
            : AnimationConfigProvider.tapConfig(for: currentEvolution, type: .bounce)

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

        Tap Config (jump):
          intensity: \(String(format: "%.3f", bounceConfig.intensity))
          decayRate: \(String(format: "%.1f", bounceConfig.decayRate))
          frequency: \(String(format: "%.1f", bounceConfig.frequency))

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
