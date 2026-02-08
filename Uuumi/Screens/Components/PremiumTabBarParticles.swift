import SwiftUI

struct PremiumTabBarParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isDarkMode: Bool
    let isActive: Bool

    private let particleCount = 48
    private let updateInterval: TimeInterval = 1.0 / 30.0

    var body: some View {
        if reduceMotion {
            staticParticles
        } else {
            animatedParticles
        }
    }

    private var staticParticles: some View {
        Canvas(rendersAsynchronously: true) { graphics, size in
            ParticleRenderer.render(
                in: graphics,
                size: size,
                time: 0,
                count: 10,
                isDarkMode: isDarkMode
            )
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.4), value: isActive)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var animatedParticles: some View {
        if isActive {
            TimelineView(.periodic(from: .now, by: updateInterval)) { timeline in
                particleCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        }
    }

    private func particleCanvas(time: Double) -> some View {
        Canvas(rendersAsynchronously: true) { graphics, size in
            ParticleRenderer.render(
                in: graphics,
                size: size,
                time: time,
                count: particleCount,
                isDarkMode: isDarkMode
            )
        }
        .allowsHitTesting(false)
    }
}

private enum ParticleRenderer {
    static let darkSparkColors: [Color] = [
        Color(red: 1.0, green: 0.95, blue: 0.8),
        Color(red: 1.0, green: 0.88, blue: 0.6),
        Color(red: 1.0, green: 0.98, blue: 0.9)
    ]

    static let lightSparkColors: [Color] = [
        Color(red: 0.85, green: 0.65, blue: 0.2),
        Color(red: 0.9, green: 0.55, blue: 0.1),
        Color(red: 0.8, green: 0.5, blue: 0.15)
    ]

    static let darkSmokeColor = Color(red: 1.0, green: 0.9, blue: 0.75)
    static let lightSmokeColor = Color(red: 0.85, green: 0.6, blue: 0.25)

    static func render(
        in context: GraphicsContext,
        size: CGSize,
        time: Double,
        count: Int,
        isDarkMode: Bool
    ) {
        let midX = size.width / 2
        let height = size.height
        let spawnHeight = height * 0.84
        let opacityMultiplier = isDarkMode ? 1.0 : 1.4
        let sparkColors = isDarkMode ? darkSparkColors : lightSparkColors
        let smokeColor = isDarkMode ? darkSmokeColor : lightSmokeColor

        for index in 0..<count {
            let seed = Double(index + 1)
            let isSmoke = index % 6 == 0

            let speed = (isSmoke ? 0.18 : 0.52) + seeded(seed, 2.1) * (isSmoke ? 0.22 : 0.58)
            let progress = (time * speed + seeded(seed, 3.7)).truncatingRemainder(dividingBy: 1.0)

            let spread = (seeded(seed, 1.3) - 0.5) * (isSmoke ? 22 : 34)
            let drift = sin(time * (0.9 + seed * 0.07) + seed * 2.0) * (isSmoke ? 3.5 : 7.5)

            let x = midX + CGFloat(spread + drift * (1 - progress))
            let originJitter = (seeded(seed, 8.1) - 0.5) * 12
            let y = (spawnHeight + CGFloat(originJitter)) - CGFloat(progress) * height

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

    private static func seeded(_ seed: Double, _ multiplier: Double) -> Double {
        sin(seed * multiplier) * 0.5 + 0.5
    }
}

#Preview("Premium Tab Bar Particles - Dark") {
    ZStack {
        Color.black.opacity(0.8)
        PremiumTabBarParticles(isDarkMode: true, isActive: true)
            .frame(width: 90, height: 120)
            .offset(y: 20)
    }
    .frame(width: 160, height: 200)
}

#Preview("Premium Tab Bar Particles - Light") {
    ZStack {
        Color.gray.opacity(0.3)
        PremiumTabBarParticles(isDarkMode: false, isActive: true)
            .frame(width: 90, height: 120)
            .offset(y: 20)
    }
    .frame(width: 160, height: 200)
}
