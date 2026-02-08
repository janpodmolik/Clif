import SwiftUI

/// Renders animated stars on a Canvas.
/// Performance-tuned: 60 stars, 20fps timeline, blooming limited to ~8 large stars.
struct StarCanvasView: View {
    /// Overall opacity of the entire star layer (used by automatic mode to fade stars in/out).
    var opacity: Double = 1.0

    @State private var starField = StarCanvasField()
    @State private var isVisible = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if reduceMotion || !isVisible {
                staticStars
            } else {
                animatedStars
            }
        }
        .opacity(opacity)
        .ignoresSafeArea()
        .mask(
            LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
        )
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .onChange(of: scenePhase) { _, newPhase in
            isVisible = newPhase == .active
        }
    }

    // MARK: - Animated

    private var animatedStars: some View {
        TimelineView(.animation(minimumInterval: 1/20)) { timeline in
            Canvas { context, size in
                let timeInterval = timeline.date.timeIntervalSince1970
                starField.ensureStars(in: size)
                starField.update(date: timeline.date)
                drawStars(context: &context, timeInterval: timeInterval)
            }
        }
    }

    // MARK: - Static (reduce motion / background)

    private var staticStars: some View {
        Canvas { context, size in
            starField.ensureStars(in: size)
            for star in starField.stars {
                let path = Path(ellipseIn: CGRect(x: star.x, y: star.y, width: star.size, height: star.size))
                context.opacity = 0.7
                context.fill(path, with: .color(white: 1))
            }
        }
    }

    // MARK: - Drawing

    private func drawStars(context: inout GraphicsContext, timeInterval: Double) {
        context.addFilter(.blur(radius: 0.3))

        for (index, star) in starField.stars.enumerated() {
            let path = Path(ellipseIn: CGRect(x: star.x, y: star.y, width: star.size, height: star.size))

            if star.flickerInterval == 0 {
                var flashLevel = sin(Double(index) + timeInterval * 4)
                flashLevel = abs(flashLevel)
                flashLevel /= 1.5
                context.opacity = 0.5 + flashLevel
            } else {
                var flashLevel = sin(Double(index) + timeInterval)
                flashLevel *= star.flickerInterval
                flashLevel -= star.flickerInterval - 1

                if flashLevel > 0 {
                    var bloomContext = context
                    bloomContext.opacity = flashLevel
                    bloomContext.addFilter(.blur(radius: 3))
                    bloomContext.fill(path, with: .color(white: 1))
                }

                context.opacity = 1
            }

            // Every 5th star gets a warm tint
            if index.isMultiple(of: 5) {
                context.fill(path, with: .color(red: 1, green: 0.85, blue: 0.8))
            } else {
                context.fill(path, with: .color(white: 1))
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.1, green: 0.1, blue: 0.4)
            .ignoresSafeArea()
        StarCanvasView()
    }
}
