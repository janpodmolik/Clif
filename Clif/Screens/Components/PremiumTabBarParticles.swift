import SwiftUI

struct PremiumTabBarParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private let particleCount = 56

    private var sparkColors: [Color] {
        if colorScheme == .dark {
            [
                Color(red: 1.0, green: 0.95, blue: 0.8),
                Color(red: 1.0, green: 0.88, blue: 0.6),
                Color(red: 1.0, green: 0.98, blue: 0.9)
            ]
        } else {
            [
                Color(red: 0.85, green: 0.65, blue: 0.2),
                Color(red: 0.9, green: 0.55, blue: 0.1),
                Color(red: 0.8, green: 0.5, blue: 0.15)
            ]
        }
    }

    private var smokeColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.9, blue: 0.75)
            : Color(red: 0.85, green: 0.6, blue: 0.25)
    }

    private var opacityMultiplier: Double {
        colorScheme == .dark ? 1.0 : 1.4
    }

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

            let baseSize = isSmoke ? 5.5 : 2.2
            let sizeVariance = isSmoke ? 4.5 : 3.0
            let particleSize = (baseSize + seeded(seed, 4.2) * sizeVariance) * (0.7 + (1 - progress) * 0.5)

            let baseOpacity = isSmoke ? 0.22 : 0.8
            let opacityVariance = isSmoke ? 0.15 : 0.3
            let opacity = (baseOpacity + seeded(seed, 5.6) * opacityVariance) * (1 - progress) * opacityMultiplier

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
