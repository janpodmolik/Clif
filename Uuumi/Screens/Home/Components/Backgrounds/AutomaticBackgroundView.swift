import SwiftUI

/// Background that continuously changes based on the device's real time of day.
/// Uses gradient stop interpolation to smoothly transition through midnight → sunrise → day → sunset → night.
/// Stars fade in at night and fade out during the day.
struct AutomaticBackgroundView: View {
    /// When set, overrides the real time of day (0.0–1.0). Used for debug previewing.
    var timeOverride: Double? = nil

    var body: some View {
        if timeOverride != nil {
            // Static render when using debug slider (no TimelineView needed)
            backgroundContent(time: timeOverride!)
        } else {
            // Update every 60 seconds — gradient changes are slow enough
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                backgroundContent(time: SkyGradient.timeOfDay())
            }
        }
    }

    @ViewBuilder
    private func backgroundContent(time: Double) -> some View {
        let color1 = SkyGradient.layer1Stops.interpolated(amount: time)
        let color2 = SkyGradient.layer2Stops.interpolated(amount: time)
        let color3 = SkyGradient.layer3Stops.interpolated(amount: time)
        let color4 = SkyGradient.layer4Stops.interpolated(amount: time)
        let starOpacity = SkyGradient.starOpacity(at: time)

        ZStack {
            LinearGradient(
                colors: [color1, color2, color3, color4],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarCanvasView(opacity: starOpacity)
        }
    }
}

#Preview {
    AutomaticBackgroundView()
}
