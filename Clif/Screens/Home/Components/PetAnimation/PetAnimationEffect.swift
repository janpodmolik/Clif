import SwiftUI

/// Transform values exported from pet animation for overlays (e.g., speech bubble).
struct PetAnimationTransform: Equatable {
    /// Rotation in degrees (from wind effect)
    let rotation: CGFloat
    /// Horizontal sway offset in points (from wind effect)
    let swayOffset: CGFloat
    /// Horizontal offset of pet's top (head) due to rotation, in points
    let topOffset: CGFloat

    static let zero = PetAnimationTransform(rotation: 0, swayOffset: 0, topOffset: 0)
}

/// A view modifier that applies pet animation effects using Metal shader and rotation.
///
/// The effect combines three layers:
/// - Idle: Continuous breathing animation (subtle vertical scale)
/// - Wind: Bending and swaying based on wind level
/// - Tap: Interactive animations triggered by user tap
///
/// All effects use synchronized wave functions and combine additively in the shader.
struct PetAnimationEffect: ViewModifier {
    // Wind parameters
    let intensity: CGFloat
    let direction: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    // Tap parameters
    let tapTime: TimeInterval
    let tapType: TapAnimationType
    let tapConfig: TapConfig

    // Idle parameters
    let idleConfig: IdleConfig
    let idlePhaseOffset: TimeInterval

    // Debug parameters
    let peakMode: Bool

    // Screen width for calculating max sample offset (pet can fly to screen edge)
    let screenWidth: CGFloat?

    /// Optional shared wind rhythm for synchronized effects with wind lines.
    /// When provided, uses rhythm's wave value instead of computing locally.
    let windRhythm: WindRhythm?

    // Callback for exporting transform values to overlays
    let onTransformUpdate: ((PetAnimationTransform) -> Void)?

    /// Local start time - only used when windRhythm is not provided (fallback mode).
    @State private var startTime = Date()

    /// Adjusted idle config with wind reduction applied
    private var adjustedIdleConfig: IdleConfig {
        guard idleConfig.enabled else { return idleConfig }

        // Reduce idle amplitude during strong wind to avoid fighting effects
        // intensity > 0.5 (medium/high wind) = reduce to 50%
        let windReduction: CGFloat = intensity > 0.5 ? 0.5 : 1.0

        return IdleConfig(
            enabled: true,
            amplitude: idleConfig.amplitude * windReduction,
            frequency: idleConfig.frequency,
            focusStart: idleConfig.focusStart,
            focusEnd: idleConfig.focusEnd
        )
    }

    /// Creates the shader with all parameters
    nonisolated private func createShader(
        time: Float,
        relativeTapTime: Float,
        idle: IdleConfig,
        peakMode: Bool,
        size: CGSize
    ) -> Shader {
        ShaderLibrary.petDistortion(
            .float(time),
            // Wind params
            .float(Float(intensity)),
            .float(Float(direction)),
            .float(Float(bendCurve)),
            .float(Float(swayAmount)),
            // Tap params
            .float(relativeTapTime),
            .float(Float(tapType.rawValue)),
            .float(Float(tapConfig.intensity)),
            .float(Float(tapConfig.decayRate)),
            .float(Float(tapConfig.frequency)),
            // Idle params (with wind reduction applied)
            .float(idle.enabled ? 1.0 : 0.0),
            .float(Float(idle.amplitude)),
            .float(Float(idle.frequency)),
            .float(Float(idle.focusStart)),
            .float(Float(idle.focusEnd)),
            // Debug
            .float(peakMode ? 1.0 : 0.0),
            // Size
            .float2(size)
        )
    }

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            // Use shared rhythm time when available, otherwise fall back to local time
            // Add idlePhaseOffset to desynchronize breathing between multiple pets
            let baseTime: TimeInterval = windRhythm?.elapsedTime ?? context.date.timeIntervalSince(startTime)
            let time: TimeInterval = baseTime + idlePhaseOffset

            // Wave function for rotation (synchronized with shader)
            // Pet bends IN the wind direction (wind pushes it)
            // Forward swing (with wind): 100% amplitude
            // Back swing (against wind): 50% amplitude
            // In peak mode: use constant -1.0 for maximum deflection
            let wave: Double = {
                if peakMode {
                    return -1.0
                } else if let rhythm = windRhythm {
                    // Use shared rhythm for synchronized effects with wind lines
                    return Double(rhythm.rawWave)
                } else {
                    // Fallback: local computation (for backward compatibility)
                    let rawWave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1
                    return rawWave < 0 ? rawWave : rawWave * 0.4
                }
            }()

            // Rotation follows wind direction (negative direction = negative rotation)
            let rotation: Double = -wave * intensity * direction * rotationAmount * 6

            // Calculate relativeTapTime independent of startTime to survive view recreation.
            // Shader does: timeSinceTap = time - tapTime
            // We want: timeSinceTap = seconds since tap = now - tapTime
            // Therefore: tapTime = time - (now - tapTime)
            let relativeTapTime: Float = tapTime > 0
                ? Float(time) - Float(Date().timeIntervalSinceReferenceDate - tapTime)
                : -1.0

            // Use adjusted idle config with wind reduction
            let idle: IdleConfig = adjustedIdleConfig

            // Calculate max sample offset
            let maxOffset: CGFloat = (screenWidth ?? 400) * 0.5

            // Capture callback and peakMode before entering Sendable closure
            let transformCallback = onTransformUpdate
            let isPeakMode = peakMode

            // Scale time for shader to match gustFrequency (so bend/sway syncs with rotation)
            let shaderTime = time * (windRhythm?.gustFrequency ?? 1.0)

            content
                .visualEffect { view, proxy in
                    let shader = createShader(
                        time: Float(shaderTime),
                        relativeTapTime: relativeTapTime,
                        idle: idle,
                        peakMode: isPeakMode,
                        size: proxy.size
                    )

                    // Calculate sway offset (same formula as shader, but inverted)
                    // Shader moves sampling position, which produces opposite visual movement
                    // So we negate to match the visual direction
                    let swayMaxOffset = proxy.size.width * 0.15 * intensity * direction
                    let swayOffset = -wave * swayMaxOffset * swayAmount * 0.3

                    // Calculate top offset from rotation (how much the head moves horizontally)
                    // When rotating around bottom anchor, the top moves: sin(angle) * height
                    let rotationRadians = rotation * .pi / 180
                    let topOffset = sin(rotationRadians) * proxy.size.height

                    // Export transform values for overlays (e.g., speech bubble)
                    if let callback = transformCallback {
                        DispatchQueue.main.async {
                            callback(PetAnimationTransform(
                                rotation: rotation,
                                swayOffset: swayOffset,
                                topOffset: topOffset
                            ))
                        }
                    }

                    return view.distortionEffect(
                        shader,
                        maxSampleOffset: CGSize(width: maxOffset, height: 50)
                    )
                }
                .rotationEffect(.degrees(rotation), anchor: .bottom)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies pet animation effects to the view (idle + wind + tap).
    ///
    /// - Parameters:
    ///   - intensity: Wind strength (0 = none, 1 = normal, 2 = strong)
    ///   - direction: Wind direction (1.0 = right, -1.0 = left)
    ///   - bendCurve: Controls bend curve steepness (lower = gentler bend for tall plants)
    ///   - swayAmount: Horizontal sway amount (0 = none, 1 = full)
    ///   - rotationAmount: Rotation intensity multiplier
    ///   - tapTime: When the tap occurred (timeIntervalSinceReferenceDate), -1 for no tap
    ///   - tapType: Type of tap animation to play
    ///   - tapConfig: Configuration for tap animation parameters
    ///   - idleConfig: Configuration for idle breathing animation
    ///   - idlePhaseOffset: Time offset to desynchronize breathing between multiple pets (0 = no offset)
    ///   - peakMode: Debug mode - freeze animation at maximum wind deflection
    ///   - screenWidth: Screen width for max sample offset (allows pet to fly to screen edge)
    ///   - windRhythm: Optional shared rhythm for synchronized wind effects with wind lines
    ///   - onTransformUpdate: Callback providing current rotation and sway values for overlays
    func petAnimation(
        intensity: CGFloat = 0.5,
        direction: CGFloat = 1.0,
        bendCurve: CGFloat = 2.0,
        swayAmount: CGFloat = 0.0,
        rotationAmount: CGFloat = 0.5,
        tapTime: TimeInterval = -1,
        tapType: TapAnimationType = .none,
        tapConfig: TapConfig = .none,
        idleConfig: IdleConfig = .default,
        idlePhaseOffset: TimeInterval = 0,
        peakMode: Bool = false,
        screenWidth: CGFloat? = nil,
        windRhythm: WindRhythm? = nil,
        onTransformUpdate: ((PetAnimationTransform) -> Void)? = nil
    ) -> some View {
        modifier(PetAnimationEffect(
            intensity: intensity,
            direction: direction,
            bendCurve: bendCurve,
            swayAmount: swayAmount,
            rotationAmount: rotationAmount,
            tapTime: tapTime,
            tapType: tapType,
            tapConfig: tapConfig,
            idleConfig: idleConfig,
            idlePhaseOffset: idlePhaseOffset,
            peakMode: peakMode,
            screenWidth: screenWidth,
            windRhythm: windRhythm,
            onTransformUpdate: onTransformUpdate
        ))
    }
}
