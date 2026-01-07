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
}
