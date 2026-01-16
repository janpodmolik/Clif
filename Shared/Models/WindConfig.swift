import Foundation

/// Configuration for wind effect parameters based on usage progress.
struct WindConfig: Equatable {
    let intensity: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    // MARK: - Interpolation Bounds

    /// Maximum wind config values (at 100% progress)
    /// These define the "strong wind" behavior - can be tuned per evolution in the future
    static let maxIntensity: CGFloat = 2.0
    static let maxBendCurve: CGFloat = 3.0
    static let maxSwayAmount: CGFloat = 11.0
    static let maxRotationAmount: CGFloat = 0.8

    /// Minimum wind config values (at 0% progress)
    static let minIntensity: CGFloat = 0
    static let minBendCurve: CGFloat = 2.0
    static let minSwayAmount: CGFloat = 0
    static let minRotationAmount: CGFloat = 1.0

    // MARK: - Interpolation

    /// Interpolates wind config based on progress (0-1).
    /// - Parameter progress: Usage progress from 0 (no usage) to 1 (limit reached)
    /// - Parameter curve: Interpolation curve type
    /// - Returns: WindConfig with interpolated values (0% = calm, 100% = strong wind)
    static func interpolated(progress: CGFloat, curve: InterpolationCurve = .easeIn) -> WindConfig {
        let t = curve.apply(min(max(progress, 0), 1))

        return WindConfig(
            intensity: lerp(from: minIntensity, to: maxIntensity, t: t),
            bendCurve: lerp(from: minBendCurve, to: maxBendCurve, t: t),
            swayAmount: lerp(from: minSwayAmount, to: maxSwayAmount, t: t),
            rotationAmount: lerp(from: minRotationAmount, to: maxRotationAmount, t: t)
        )
    }

    private static func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

/// Curve type for wind config interpolation
enum InterpolationCurve: String, CaseIterable {
    case linear = "Linear"
    case easeIn = "Ease In"

    func apply(_ t: CGFloat) -> CGFloat {
        switch self {
        case .linear:
            return t
        case .easeIn:
            // Quadratic ease-in: slow start, fast end
            return t * t
        }
    }
}
