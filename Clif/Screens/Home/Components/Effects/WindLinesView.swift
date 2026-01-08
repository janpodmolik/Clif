import SwiftUI

/// Anime-style wind lines effect that scales with WindLevel intensity.
/// Uses "head + trail" approach - the head follows a trajectory and leaves a fading trail behind.
struct WindLinesView: View {
    let windLevel: WindLevel
    var debugColors: Bool = false  // When true, show different colors per trajectory type

    @Environment(\.colorScheme) private var colorScheme
    @State private var activeLines: [WindLine] = []
    @State private var lastSpawnTime: Double = 0

    private var lineColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func colorForLine(_ line: WindLine) -> Color {
        guard debugColors else { return lineColor }

        switch line.trajectory.trajectoryType {
        case .wave:
            return .blue
        case .sCurve:
            return .green
        case .loop:
            return .red
        }
    }

    private var config: WindLinesConfig {
        WindLinesConfig(for: windLevel)
    }

    var body: some View {
        if windLevel != .none {
            TimelineView(.animation) { timeline in
                let currentTime = timeline.date.timeIntervalSince1970

                Canvas { context, size in
                    for line in activeLines {
                        drawLine(line, currentTime: currentTime, context: &context, size: size)
                    }
                }
                .onChange(of: timeline.date) { _, _ in
                    updateLines(currentTime: currentTime)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Line Drawing

    private func drawLine(_ line: WindLine, currentTime: Double, context: inout GraphicsContext, size: CGSize) {
        let elapsed = currentTime - line.spawnTime
        let totalDuration = line.duration

        guard elapsed >= 0 && elapsed <= totalDuration else { return }

        // Head position along the trajectory (0 to 1)
        let headProgress = elapsed / totalDuration

        // Trail length scales with line length (shorter lines = shorter trails)
        let maxTrailLength: Double = 0.20 * Double(line.trajectory.length) + 0.08
        let trailLength: Double
        if headProgress < maxTrailLength {
            // Growing trail at start
            trailLength = headProgress
        } else if headProgress > (1 - maxTrailLength) {
            // Shrinking trail at end
            trailLength = 1 - headProgress
        } else {
            trailLength = maxTrailLength
        }

        let tailProgress = max(0, headProgress - trailLength)

        // Generate trail points from tail to head
        let numPoints = 30
        var trailPoints: [CGPoint] = []

        for i in 0...numPoints {
            let t = tailProgress + (headProgress - tailProgress) * Double(i) / Double(numPoints)
            let point = line.trajectory.position(at: CGFloat(t), in: size)
            trailPoints.append(point)
        }

        guard trailPoints.count >= 2 else { return }

        // Draw tapered trail
        let path = createTaperedTrail(points: trailPoints, maxThickness: line.thickness)

        // Opacity based on overall progress
        let opacity = calculateOpacity(progress: headProgress)
        context.fill(path, with: .color(colorForLine(line).opacity(opacity)))
    }

    private func createTaperedTrail(points: [CGPoint], maxThickness: CGFloat) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        let segments = points.count - 1
        var topPoints: [CGPoint] = []
        var bottomPoints: [CGPoint] = []

        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = points[i]

            // Taper: thin at tail (t=0), thick at head (t=1), with smooth falloff at very end
            let taperFactor: CGFloat
            if t < 0.1 {
                // Thin at the very tail
                taperFactor = t / 0.1
            } else if t > 0.95 {
                // Slightly thin at head tip
                taperFactor = (1 - t) / 0.05
            } else {
                taperFactor = 1.0
            }

            let halfWidth = (maxThickness / 2) * taperFactor

            // Get perpendicular direction from tangent
            let tangent: CGPoint
            if i == 0 {
                tangent = CGPoint(
                    x: points[1].x - points[0].x,
                    y: points[1].y - points[0].y
                )
            } else if i == segments {
                tangent = CGPoint(
                    x: points[segments].x - points[segments - 1].x,
                    y: points[segments].y - points[segments - 1].y
                )
            } else {
                tangent = CGPoint(
                    x: points[i + 1].x - points[i - 1].x,
                    y: points[i + 1].y - points[i - 1].y
                )
            }

            let length = sqrt(tangent.x * tangent.x + tangent.y * tangent.y)
            guard length > 0 else { continue }

            let normal = CGPoint(x: -tangent.y / length, y: tangent.x / length)

            topPoints.append(CGPoint(
                x: point.x + normal.x * halfWidth,
                y: point.y + normal.y * halfWidth
            ))
            bottomPoints.append(CGPoint(
                x: point.x - normal.x * halfWidth,
                y: point.y - normal.y * halfWidth
            ))
        }

        guard let firstTop = topPoints.first else { return path }
        path.move(to: firstTop)

        for point in topPoints.dropFirst() {
            path.addLine(to: point)
        }

        for point in bottomPoints.reversed() {
            path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }

    // MARK: - Line Management

    private func updateLines(currentTime: Double) {
        // Remove finished lines
        activeLines.removeAll { line in
            let elapsed = currentTime - line.spawnTime
            return elapsed > line.duration + 0.1
        }

        // Maybe spawn new line
        let timeSinceLastSpawn = currentTime - lastSpawnTime
        if activeLines.count < config.maxLines && timeSinceLastSpawn > config.minSpawnInterval {
            if Double.random(in: 0...1) < config.spawnChance {
                activeLines.append(WindLine.random(config: config, spawnTime: currentTime))
                lastSpawnTime = currentTime
            }
        }
    }

    private func calculateOpacity(progress: Double) -> Double {
        if progress < 0.15 {
            return progress / 0.15
        } else if progress > 0.85 {
            return (1 - progress) / 0.15
        }
        return 1.0
    }
}

// MARK: - Wind Line

private struct WindLine: Identifiable {
    let id = UUID()
    let trajectory: Trajectory
    let thickness: CGFloat
    let duration: Double
    let spawnTime: Double

    static func random(config: WindLinesConfig, spawnTime: Double) -> WindLine {
        let trajectory = Trajectory.random()
        // Duration scales with length - shorter lines move faster
        let baseDuration = Double.random(in: config.durationRange)
        let scaledDuration = baseDuration * (0.5 + Double(trajectory.length) * 0.5)

        return WindLine(
            trajectory: trajectory,
            thickness: CGFloat.random(in: 2.5...4.5),
            duration: scaledDuration,
            spawnTime: spawnTime
        )
    }
}

// MARK: - Trajectory

private struct Trajectory {
    let startY: CGFloat      // Normalized 0-1
    let endYOffset: CGFloat  // How much Y changes from start to end
    let length: CGFloat      // Normalized length (0.15-1.0)
    let trajectoryType: TrajectoryType
    let seed: UInt64

    static func random() -> Trajectory {
        // End Y offset: can go up or down by up to 15% of screen
        let endOffset = CGFloat.random(in: -0.15...0.15)

        return Trajectory(
            startY: CGFloat.random(in: 0.08...0.42), // Top half of screen only
            endYOffset: endOffset,
            length: CGFloat.random(in: 0.15...1.0), // Variable length, some very short
            trajectoryType: TrajectoryType.random(),
            seed: UInt64.random(in: 0...UInt64.max)
        )
    }

    /// Get position at progress t (0 = start, 1 = end)
    func position(at t: CGFloat, in size: CGSize) -> CGPoint {
        var rng = SeededRNG(seed: seed)

        // Base horizontal movement: left to right across screen
        let startX = -size.width * 0.1
        let endX = size.width * 1.1
        let baseX = startX + t * (endX - startX)

        // Y position interpolates from startY to startY + endYOffset
        let startYPos = startY * size.height
        let endYPos = (startY + endYOffset) * size.height
        let baseY = startYPos + t * (endYPos - startYPos)

        // Base wave that ALL trajectories have (never fully straight)
        let baseWaveAmp = CGFloat.random(in: 12...22, using: &rng)
        let baseWaveFreq = CGFloat.random(in: 1.5...2.5, using: &rng)
        let baseWave = sin(t * .pi * baseWaveFreq) * baseWaveAmp

        switch trajectoryType {
        case .wave:
            // Single smooth arc - gentle curve up or down
            let amplitude = CGFloat.random(in: 25...45, using: &rng)
            let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1
            let flowWave = sin(t * .pi) * amplitude * direction
            return CGPoint(x: baseX, y: baseY + baseWave + flowWave)

        case .sCurve:
            // Double wave - goes up then down (or vice versa)
            let amplitude = CGFloat.random(in: 35...55, using: &rng)
            let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1
            // Two full humps
            let doubleWave = sin(t * 2 * .pi) * amplitude * direction
            return CGPoint(x: baseX, y: baseY + doubleWave)

        case .loop:
            // Smooth loop with continuous wave before and after
            let loopRadius = CGFloat.random(in: 30...55, using: &rng)
            let loopCenter = CGFloat.random(in: 0.35...0.65, using: &rng)
            let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1

            // Smooth blend factor: 0 outside loop, 1 at loop center
            let loopWidth: CGFloat = 0.20
            let distFromLoop = abs(t - loopCenter)
            let loopBlend = smoothstep(loopWidth, 0, distFromLoop)

            // Wave position (continuous throughout)
            let waveY = baseY + baseWave

            if loopBlend > 0.01 {
                // Inside or near loop region - blend between wave and circle
                let normalizedT = (t - loopCenter + loopWidth) / (2 * loopWidth)
                let clampedT = max(0, min(1, normalizedT))
                let angle = clampedT * 2 * .pi * direction

                // Circle center follows the base trajectory
                let loopCenterX = startX + loopCenter * (endX - startX)
                let loopBaseY = startYPos + loopCenter * (endYPos - startYPos)
                let loopCenterY = loopBaseY + sin(loopCenter * .pi * baseWaveFreq) * baseWaveAmp

                // Position on circle
                let circleX = loopCenterX + sin(angle) * loopRadius
                let circleY = loopCenterY - loopRadius * direction + cos(angle) * loopRadius * direction

                // Blend between wave path and loop path
                let blendedX = baseX * (1 - loopBlend) + circleX * loopBlend
                let blendedY = waveY * (1 - loopBlend) + circleY * loopBlend

                return CGPoint(x: blendedX, y: blendedY)
            } else {
                // Outside loop - just the wave
                return CGPoint(x: baseX, y: waveY)
            }
        }
    }

    /// Attempt at smoothstep for blending
    private func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }
}

private enum TrajectoryType: CaseIterable {
    case wave
    case sCurve
    case loop

    static func random() -> TrajectoryType {
        let roll = Double.random(in: 0...1)
        if roll < 0.40 { return .wave }
        if roll < 0.75 { return .sCurve }
        return .loop  // 25% chance
    }
}

// MARK: - Seeded Random

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

private extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, using rng: inout SeededRNG) -> CGFloat {
        let value = Double(rng.next() % 1_000_000) / 1_000_000.0
        return range.lowerBound + CGFloat(value) * (range.upperBound - range.lowerBound)
    }
}

private extension Bool {
    static func random(using rng: inout SeededRNG) -> Bool {
        rng.next() % 2 == 0
    }
}

// MARK: - Config

private struct WindLinesConfig {
    let maxLines: Int
    let minSpawnInterval: Double
    let spawnChance: Double
    let durationRange: ClosedRange<Double>

    init(for windLevel: WindLevel) {
        switch windLevel {
        case .none:
            maxLines = 0
            minSpawnInterval = 999
            spawnChance = 0
            durationRange = 1...1

        case .low:
            maxLines = 3
            minSpawnInterval = 0.6
            spawnChance = 0.04
            durationRange = 2.5...3.5

        case .medium:
            maxLines = 5
            minSpawnInterval = 0.4
            spawnChance = 0.06
            durationRange = 2.0...3.0

        case .high:
            maxLines = 7
            minSpawnInterval = 0.25
            spawnChance = 0.10
            durationRange = 1.5...2.5
        }
    }
}

// MARK: - Previews

#Preview("Wind Lines - Low") {
    ZStack {
        Color.gray.opacity(0.2)
        WindLinesView(windLevel: .low)
    }
}

#Preview("Wind Lines - High") {
    ZStack {
        Color.gray.opacity(0.2)
        WindLinesView(windLevel: .high)
    }
}

#Preview("Wind Lines - Dark") {
    ZStack {
        Color.black
        WindLinesView(windLevel: .medium)
    }
    .preferredColorScheme(.dark)
}
