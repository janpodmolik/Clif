import SwiftUI

/// A view modifier that applies wind animation effect using Metal shader and rotation.
///
/// The effect combines:
/// - Metal shader distortion (bending the top while keeping bottom stable)
/// - SwiftUI rotation for natural swaying motion
///
/// Both effects use synchronized wave functions for coherent animation.
struct WindEffect: ViewModifier {
    let intensity: CGFloat
    let direction: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat
    let rotationAmount: CGFloat

    @State private var startTime = Date()

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(startTime)

            // Wave function for rotation (synchronized with shader)
            let wave = sin(time * 1.5) * 0.6 + sin(time * 2.3) * 0.3 + sin(time * 0.7) * 0.1

            // Rotation follows wind direction (negative direction = negative rotation)
            let rotation = -wave * intensity * direction * rotationAmount * 6

            content
                .visualEffect { view, proxy in
                    view.distortionEffect(
                        ShaderLibrary.windDistortion(
                            .float(Float(time)),
                            .float(Float(intensity)),
                            .float(Float(direction)),
                            .float(Float(bendCurve)),
                            .float(Float(swayAmount)),
                            .float2(proxy.size)
                        ),
                        maxSampleOffset: CGSize(width: 100, height: 0)
                    )
                }
                .rotationEffect(.degrees(rotation), anchor: .bottom)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies wind animation effect to the view.
    ///
    /// - Parameters:
    ///   - intensity: Wind strength (0 = none, 1 = normal, 2 = strong)
    ///   - direction: Wind direction (1.0 = right, -1.0 = left)
    ///   - bendCurve: Controls bend curve steepness (lower = gentler bend for tall plants)
    ///   - swayAmount: Horizontal sway amount (0 = none, 1 = full)
    ///   - rotationAmount: Rotation intensity multiplier
    func windEffect(
        intensity: CGFloat = 0.5,
        direction: CGFloat = 1.0,
        bendCurve: CGFloat = 2.0,
        swayAmount: CGFloat = 0.0,
        rotationAmount: CGFloat = 0.5
    ) -> some View {
        modifier(WindEffect(
            intensity: intensity,
            direction: direction,
            bendCurve: bendCurve,
            swayAmount: swayAmount,
            rotationAmount: rotationAmount
        ))
    }
}
