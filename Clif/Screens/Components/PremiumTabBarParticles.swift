import SwiftUI

struct PremiumTabBarParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particleCount = 28
    private let sparkColors: [Color] = [
        Color(red: 1.0, green: 0.95, blue: 0.8),
        Color(red: 1.0, green: 0.88, blue: 0.6),
        Color(red: 1.0, green: 0.98, blue: 0.9)
    ]
    private let smokeColor = Color(red: 1.0, green: 0.9, blue: 0.75)

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { graphics, size in
                    renderParticles(in: graphics, size: size, time: 0, count: 10)
                }
            } else {
                TimelineView(.animation) { timeline in
                    Canvas { graphics, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        renderParticles(in: graphics, size: size, time: time, count: particleCount)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func renderParticles(in context: GraphicsContext, size: CGSize, time: Double, count: Int) {
        let midX = size.width / 2
        let height = size.height

        for index in 0..<count {
            let seed = Double(index + 1)
            let isSmoke = index % 6 == 0

            let speed = (isSmoke ? 0.18 : 0.52) + seeded(seed, 2.1) * (isSmoke ? 0.22 : 0.58)
            let progress = (time * speed + seeded(seed, 3.7)).truncatingRemainder(dividingBy: 1.0)

            let spread = (seeded(seed, 1.3) - 0.5) * (isSmoke ? 22 : 34)
            let drift = sin(time * (0.9 + seed * 0.07) + seed * 2.0) * (isSmoke ? 3.5 : 7.5)

            let x = midX + CGFloat(spread + drift * (1 - progress))
            let y = height - CGFloat(progress) * height

            let baseSize = isSmoke ? 4.5 : 1.6
            let sizeVariance = isSmoke ? 3.8 : 2.2
            let particleSize = (baseSize + seeded(seed, 4.2) * sizeVariance) * (0.7 + (1 - progress) * 0.5)

            let baseOpacity = isSmoke ? 0.18 : 0.7
            let opacityVariance = isSmoke ? 0.12 : 0.25
            let opacity = (baseOpacity + seeded(seed, 5.6) * opacityVariance) * (1 - progress)

            let color = isSmoke ? smokeColor : sparkColors[index % sparkColors.count]
            let rect = CGRect(
                x: x - particleSize / 2,
                y: y - particleSize / 2,
                width: particleSize,
                height: particleSize
            )
            context.fill(Circle().path(in: rect), with: .color(color.opacity(opacity)))
        }
    }

    private func seeded(_ seed: Double, _ multiplier: Double) -> Double {
        sin(seed * multiplier) * 0.5 + 0.5
    }
}

#Preview("Premium Tab Bar Particles") {
    ZStack {
        Color.black.opacity(0.8)
        PremiumTabBarParticles()
            .frame(width: 90, height: 120)
            .offset(y: 20)
    }
    .frame(width: 160, height: 200)
}
