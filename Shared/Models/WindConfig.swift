import Foundation

/// Configuration for wind effect parameters based on usage progress.
struct WindConfig: Equatable {
    let intensity: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    // MARK: - Interpolation

    /// Interpolates wind config based on progress (0-1).
    /// - Parameter progress: Usage progress from 0 (no usage) to 1 (limit reached)
    /// - Parameter curve: Interpolation curve type
    /// - Parameter bounds: Min/max bounds and per-parameter exponents
    /// - Returns: WindConfig with interpolated values (0% = calm, 100% = strong wind)
    static func interpolated(
        progress: CGFloat,
        curve: InterpolationCurve = .linear,
        bounds: WindConfigBounds = .default
    ) -> WindConfig {
        let baseCurve = curve.apply(min(max(progress, 0), 1))

        return WindConfig(
            intensity: bounds.intensity.interpolate(t: baseCurve),
            bendCurve: bounds.bendCurve.interpolate(t: baseCurve),
            swayAmount: bounds.swayAmount.interpolate(t: baseCurve),
            rotationAmount: bounds.rotationAmount.interpolate(t: baseCurve)
        )
    }

    private static func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

/// Bounds for a single wind parameter with min, max, and per-parameter exponent.
struct WindParamBounds: Equatable {
    var min: CGFloat
    var max: CGFloat
    /// Per-parameter exponent applied after base curve. 1.0 = no change, >1 = slower start, <1 = faster start
    var exponent: CGFloat

    func interpolate(t: CGFloat) -> CGFloat {
        let adjusted = pow(t, exponent)
        return min + (max - min) * adjusted
    }

    static func == (lhs: WindParamBounds, rhs: WindParamBounds) -> Bool {
        lhs.min == rhs.min && lhs.max == rhs.max && lhs.exponent == rhs.exponent
    }
}

/// Collection of bounds for all wind config parameters.
struct WindConfigBounds: Equatable {
    var intensity: WindParamBounds
    var bendCurve: WindParamBounds
    var swayAmount: WindParamBounds
    var rotationAmount: WindParamBounds

    static let `default` = WindConfigBounds(
        intensity: WindParamBounds(min: 0, max: 2.0, exponent: 1.0),
        bendCurve: WindParamBounds(min: 2.0, max: 3.0, exponent: 1.0),
        swayAmount: WindParamBounds(min: 0, max: 11.0, exponent: 1.0),
        rotationAmount: WindParamBounds(min: 1.0, max: 0.8, exponent: 1.0)
    )
}

/// Curve type for wind config interpolation
enum InterpolationCurve: String, CaseIterable {
    case linear = "Linear"

    func apply(_ t: CGFloat) -> CGFloat {
        t
    }
}
