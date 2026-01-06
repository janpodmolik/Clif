import SwiftUI

struct WindEffect: ViewModifier {
    let intensity: CGFloat
    let direction: CGFloat
    let bendCurve: CGFloat
    let swayAmount: CGFloat

    @State private var startTime = Date()

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let time = Float(context.date.timeIntervalSince(startTime))

            content
                .drawingGroup()
                .visualEffect { view, proxy in
                    view.distortionEffect(
                        ShaderLibrary.windDistortion(
                            .float(time),
                            .float(Float(intensity)),
                            .float(Float(direction)),
                            .float(Float(bendCurve)),
                            .float(Float(swayAmount)),
                            .float2(proxy.size)
                        ),
                        maxSampleOffset: CGSize(width: 100, height: 0)
                    )
                }
        }
    }
}

extension View {
    func windEffect(
        intensity: CGFloat = 0.5,
        direction: CGFloat = 1.0,
        bendCurve: CGFloat = 2.0,
        swayAmount: CGFloat = 0.0
    ) -> some View {
        modifier(WindEffect(
            intensity: intensity,
            direction: direction,
            bendCurve: bendCurve,
            swayAmount: swayAmount
        ))
    }
}
