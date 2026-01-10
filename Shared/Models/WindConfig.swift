import Foundation

/// Configuration for wind effect parameters at a specific wind level.
struct WindConfig: Equatable {
    let intensity: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    /// No wind effect - completely still
    static let none = WindConfig(
        intensity: 0,
        bendCurve: 2.0,
        swayAmount: 0,
        rotationAmount: 0
    )

    /// Low wind - gentle breeze
    static let low = WindConfig(
        intensity: 0.5,
        bendCurve: 2.5,
        swayAmount: 4.9,
        rotationAmount: 1.0
    )

    /// Medium wind - moderate movement
    static let medium = WindConfig(
        intensity: 1.5,
        bendCurve: 2.5,
        swayAmount: 7.5,
        rotationAmount: 0.8
    )

    /// High wind - strong gusts
    static let high = WindConfig(
        intensity: 2.0,
        bendCurve: 3.0,
        swayAmount: 11.0,
        rotationAmount: 0.8
    )

    /// Returns default config for given wind level
    static func `default`(for level: WindLevel) -> WindConfig {
        switch level {
        case .none: return .none
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}
