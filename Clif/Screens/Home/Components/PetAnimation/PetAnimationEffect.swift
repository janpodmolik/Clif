import SwiftUI

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

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(startTime)

            // Wave function for rotation (synchronized with shader)
            // Pet bends IN the wind direction (wind pushes it)
            // Forward swing (with wind): 100% amplitude
            // Back swing (against wind): 50% amplitude
            let rawWave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1
            let wave = rawWave < 0 ? rawWave : rawWave * 0.5

            // Rotation follows wind direction (negative direction = negative rotation)
            let rotation = -wave * intensity * direction * rotationAmount * 6

            // Calculate tap time relative to shader start time
            let relativeTapTime: Float = tapTime > 0
                ? Float(tapTime - startTime.timeIntervalSinceReferenceDate)
                : -1.0

            // Use adjusted idle config with wind reduction
            let idle = adjustedIdleConfig

            content
                .visualEffect { view, proxy in
                    view.distortionEffect(
                        ShaderLibrary.petDistortion(
                            .float(Float(time)),
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
                            // Size
                            .float2(proxy.size)
                        ),
                        maxSampleOffset: CGSize(width: 100, height: 50)
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
    func petAnimation(
        intensity: CGFloat = 0.5,
        direction: CGFloat = 1.0,
        bendCurve: CGFloat = 2.0,
        swayAmount: CGFloat = 0.0,
        rotationAmount: CGFloat = 0.5,
        tapTime: TimeInterval = -1,
        tapType: TapAnimationType = .none,
        tapConfig: TapConfig = .none,
        idleConfig: IdleConfig = .default
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
            idleConfig: idleConfig
        ))
    }
}
