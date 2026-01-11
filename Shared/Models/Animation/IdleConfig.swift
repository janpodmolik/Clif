import Foundation

/// Configuration for idle breathing animation.
struct IdleConfig: Equatable, Hashable {
    /// Whether idle animation is enabled.
    var enabled: Bool

    /// Scale amplitude (0.03 = 3% size increase at peak breath).
    var amplitude: CGFloat

    /// Breathing frequency in Hz (0.4 = one breath every 2.5 seconds).
    var frequency: CGFloat

    /// Where the breathing effect starts to fade (0 = bottom, 1 = top).
    /// Values below this get full effect.
    var focusStart: CGFloat

    /// Where the breathing effect fully fades out (0 = bottom, 1 = top).
    /// Values above this get no effect.
    var focusEnd: CGFloat

    /// Default idle configuration - subtle breathing focused on lower 2/3.
    static let `default` = IdleConfig(
        enabled: true,
        amplitude: 0.03,
        frequency: 0.4,
        focusStart: 0.33,
        focusEnd: 0.7
    )

    /// Disabled idle animation.
    static let none = IdleConfig(
        enabled: false,
        amplitude: 0,
        frequency: 0,
        focusStart: 0.33,
        focusEnd: 0.7
    )
}
