import SwiftUI

struct NightBackgroundView: View {
    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.1, blue: 0.4),
            Color(red: 0.3, green: 0.3, blue: 0.7),
            Color(red: 0.6, green: 0.5, blue: 0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Reduced from 100 to 50 stars for better performance
    @State private var stars: [Star] = (0..<50).map { _ in Star.random() }
    @State private var shootingStar: ShootingStar? = nil
    @State private var isVisible = true
    @State private var shootingStarTask: Task<Void, Never>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            gradient
                .ignoresSafeArea()

            if !reduceMotion && isVisible {
                // Use lower frame rate (1/20 = 20fps) for star pulsing - it's subtle enough
                TimelineView(.animation(minimumInterval: 1/20)) { timeline in
                    Canvas { context, size in
                        let currentTime = timeline.date.timeIntervalSince1970
                        for star in stars {
                            let position = CGPoint(x: star.x * size.width, y: star.y * size.height)
                            let starSize = star.size * 3
                            let pulse = sin(currentTime * star.pulseSpeed) * 0.3 + 0.7
                            context.fill(
                                Circle().path(in: CGRect(x: position.x, y: position.y, width: starSize, height: starSize)),
                                with: .color(Color.white.opacity(star.opacity * pulse))
                            )
                        }
                    }
                }
            } else {
                // Static stars when animations are disabled or view is not visible
                Canvas { context, size in
                    for star in stars {
                        let position = CGPoint(x: star.x * size.width, y: star.y * size.height)
                        let starSize = star.size * 3
                        context.fill(
                            Circle().path(in: CGRect(x: position.x, y: position.y, width: starSize, height: starSize)),
                            with: .color(Color.white.opacity(star.opacity * 0.7))
                        )
                    }
                }
            }

            if let shootingStar = shootingStar, !reduceMotion {
                ShootingStarView(star: shootingStar)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + shootingStar.duration) {
                            self.shootingStar = nil
                            scheduleNextShootingStar()
                        }
                    }
            }
        }
        .onAppear {
            isVisible = true
            scheduleNextShootingStar()
        }
        .onDisappear {
            isVisible = false
            shootingStarTask?.cancel()
            shootingStarTask = nil
        }
        .onChange(of: scenePhase) { _, newPhase in
            isVisible = newPhase == .active
            if newPhase == .active {
                scheduleNextShootingStar()
            } else {
                shootingStarTask?.cancel()
                shootingStarTask = nil
            }
        }
    }

    private func scheduleNextShootingStar() {
        guard !reduceMotion else { return }
        shootingStarTask?.cancel()
        shootingStarTask = Task { @MainActor in
            let delay = Double.random(in: 5...15)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self.shootingStar = ShootingStar.random()
        }
    }
}

// MARK: - Star Models

private struct Star {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: CGFloat
    let pulseSpeed: Double

    static func random() -> Star {
        Star(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 0.5...1.5),
            opacity: CGFloat.random(in: 0.4...1.0),
            pulseSpeed: Double.random(in: 0.5...1.5)
        )
    }
}

private struct ShootingStar {
    let start: CGPoint
    let end: CGPoint
    let duration: Double

    @MainActor static func random() -> ShootingStar {
        let startX = CGFloat.random(in: -0.4...1.4)
        let startY = CGFloat.random(in: 0.1...0.5)
        let endX = startX + CGFloat.random(in: -0.5...0.5)
        let endY = startY + CGFloat.random(in: 0.1...0.3)

        return ShootingStar(
            start: CGPoint(x: startX * UIScreen.main.bounds.width, y: startY * UIScreen.main.bounds.height),
            end: CGPoint(x: endX * UIScreen.main.bounds.width, y: endY * UIScreen.main.bounds.height),
            duration: Double.random(in: 1.0...2.5)
        )
    }
}

private struct ShootingStarView: View {
    let star: ShootingStar
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 4, height: 4)
            .offset(x: isAnimating ? star.end.x - star.start.x : 0, y: isAnimating ? star.end.y - star.start.y : 0)
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    NightBackgroundView()
}
