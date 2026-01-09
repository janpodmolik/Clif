import SwiftUI

/// Anime-style wind lines effect that scales with WindLevel intensity.
/// Uses "head + trail" approach - the head follows a trajectory and leaves a fading trail behind.
struct WindLinesView: View {
    let windLevel: WindLevel
    var direction: CGFloat = 1.0  // 1.0 = left→right, -1.0 = right→left
    var debugColors: Bool = false  // When true, show different colors per trajectory type

    /// Wind area bounds (normalized 0-1, where 0 = top, 1 = bottom)
    /// Lines spawn within this vertical range, centered around the pet
    var windAreaTop: CGFloat = 0.08
    var windAreaBottom: CGFloat = 0.42

    /// Override config for special effects (e.g., burst mode for blow away)
    var overrideConfig: WindLinesConfig? = nil

    /// Optional shared wind rhythm for synchronized gusts with pet animation.
    /// When provided, spawn rate and speed vary with gust intensity.
    var windRhythm: WindRhythm?

    @Environment(\.colorScheme) private var colorScheme
    @State private var activeLines: [WindLine] = []
    @State private var lastSpawnTime: Double = 0
    @State private var lastBurstTime: Double = 0

    private var lineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.white.opacity(0.4)
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
        overrideConfig ?? WindLinesConfig(for: windLevel)
    }

    private var gustConfig: WindGustConfig {
        WindGustConfig(for: windLevel)
    }

    var body: some View {
        if windLevel != .none || overrideConfig != nil {
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

        // Get current gust intensity from rhythm (0-1), default to 0.5 if no rhythm
        let gustIntensity = windRhythm?.gustIntensity ?? 0.5

        // Calculate dynamic spawn parameters based on gust
        let effectiveSpawnChance: Double
        let speedMultiplier: Double

        if overrideConfig != nil {
            // Burst mode (blow away) - ignore gust rhythm, use override config directly
            effectiveSpawnChance = config.spawnChance
            speedMultiplier = 1.0
        } else if windRhythm != nil {
            // Synchronized mode - spawn rate and speed vary with gust intensity
            effectiveSpawnChance = gustConfig.spawnChance(at: gustIntensity)
            speedMultiplier = gustConfig.speedMultiplier(at: gustIntensity)

            // Burst spawn at peak gusts - always spawn 2 loop lines for dramatic effect
            let timeSinceLastBurst = currentTime - lastBurstTime
            if gustIntensity > gustConfig.burstThreshold &&
               activeLines.count < config.maxLines - 2 &&
               timeSinceLastBurst > 0.3 {
                // Spawn 2 guaranteed loop lines
                for _ in 0..<2 where activeLines.count < config.maxLines {
                    activeLines.append(WindLine.random(
                        config: config,
                        spawnTime: currentTime,
                        windAreaTop: windAreaTop,
                        windAreaBottom: windAreaBottom,
                        direction: direction,
                        speedMultiplier: speedMultiplier,
                        forcedType: .loop
                    ))
                }
                lastBurstTime = currentTime
                lastSpawnTime = currentTime
                return
            }
        } else {
            // Legacy mode - constant spawn rate from config
            effectiveSpawnChance = config.spawnChance
            speedMultiplier = 1.0
        }

        // Regular spawn logic
        let timeSinceLastSpawn = currentTime - lastSpawnTime
        if activeLines.count < config.maxLines && timeSinceLastSpawn > config.minSpawnInterval {
            if Double.random(in: 0...1) < effectiveSpawnChance {
                activeLines.append(WindLine.random(
                    config: config,
                    spawnTime: currentTime,
                    windAreaTop: windAreaTop,
                    windAreaBottom: windAreaBottom,
                    direction: direction,
                    speedMultiplier: speedMultiplier
                ))
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

    static func random(
        config: WindLinesConfig,
        spawnTime: Double,
        windAreaTop: CGFloat,
        windAreaBottom: CGFloat,
        direction: CGFloat,
        speedMultiplier: Double = 1.0,
        forcedType: TrajectoryType? = nil
    ) -> WindLine {
        let trajectory = Trajectory.random(
            windAreaTop: windAreaTop,
            windAreaBottom: windAreaBottom,
            direction: direction,
            forcedType: forcedType
        )
        // Duration scales with length - shorter lines move faster
        let baseDuration = Double.random(in: config.durationRange)
        let scaledDuration = baseDuration * (0.5 + Double(trajectory.length) * 0.5)

        // Apply speed multiplier (faster = shorter duration)
        let adjustedDuration = scaledDuration / speedMultiplier

        return WindLine(
            trajectory: trajectory,
            thickness: CGFloat.random(in: 2.5...4.5),
            duration: adjustedDuration,
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
    let direction: CGFloat   // 1.0 = left→right, -1.0 = right→left

    static func random(
        windAreaTop: CGFloat,
        windAreaBottom: CGFloat,
        direction: CGFloat,
        forcedType: TrajectoryType? = nil
    ) -> Trajectory {
        // End Y offset: can go up or down within the wind area bounds
        let areaHeight = windAreaBottom - windAreaTop
        let maxOffset = areaHeight * 0.4  // Allow some vertical drift
        let endOffset = CGFloat.random(in: -maxOffset...maxOffset)

        // Loops need longer length to look good
        let trajectoryType = forcedType ?? TrajectoryType.random()
        let length: CGFloat = trajectoryType == .loop
            ? CGFloat.random(in: 0.6...1.0)
            : CGFloat.random(in: 0.15...1.0)

        return Trajectory(
            startY: CGFloat.random(in: windAreaTop...windAreaBottom),
            endYOffset: endOffset,
            length: length,
            trajectoryType: trajectoryType,
            seed: UInt64.random(in: 0...UInt64.max),
            direction: direction
        )
    }

    /// Get position at progress t (0 = start, 1 = end)
    func position(at t: CGFloat, in size: CGSize) -> CGPoint {
        var rng = SeededRNG(seed: seed)

        // Base horizontal movement: direction determines start/end
        let startX = direction > 0 ? -size.width * 0.1 : size.width * 1.1
        let endX = direction > 0 ? size.width * 1.1 : -size.width * 0.1
        let baseDX = endX - startX

        // Y position interpolates from startY to startY + endYOffset
        let startYPos = startY * size.height
        let endYPos = (startY + endYOffset) * size.height
        let baseDYLinear = endYPos - startYPos

        // Base wave that ALL trajectories have (never fully straight)
        let baseWaveAmp = CGFloat.random(in: 12...22, using: &rng)
        let baseWaveFreq = CGFloat.random(in: 1.5...2.5, using: &rng)

        func baseComponents(at t: CGFloat) -> (x: CGFloat, y: CGFloat, wave: CGFloat, dy: CGFloat) {
            let baseX = startX + t * baseDX
            let baseY = startYPos + t * baseDYLinear
            let baseWave = sin(t * .pi * baseWaveFreq) * baseWaveAmp
            let baseDY = baseDYLinear + cos(t * .pi * baseWaveFreq) * (.pi * baseWaveFreq) * baseWaveAmp
            return (baseX, baseY, baseWave, baseDY)
        }

        let base = baseComponents(at: t)

        switch trajectoryType {
        case .wave:
            // Single smooth arc - gentle curve up or down
            let amplitude = CGFloat.random(in: 25...45, using: &rng)
            let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1
            let flowWave = sin(t * .pi) * amplitude * direction
            return CGPoint(x: base.x, y: base.y + base.wave + flowWave)

        case .sCurve:
            // Double wave - goes up then down (or vice versa)
            let amplitude = CGFloat.random(in: 35...55, using: &rng)
            let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1
            // Two full humps
            let doubleWave = sin(t * 2 * .pi) * amplitude * direction
            return CGPoint(x: base.x, y: base.y + doubleWave)

        case .loop:
            // Smooth loop with continuous wave before and after
            let loopRadius = CGFloat.random(in: 50...90, using: &rng)
            let loopCenter = CGFloat.random(in: 0.35...0.65, using: &rng)
            // verticalDir: -1 = loop goes UP (negative Y), +1 = loop goes DOWN
            let verticalDir: CGFloat = Bool.random(using: &rng) ? -1 : 1

            // Smooth blend factor: 0 outside loop, 1 at loop center
            let loopWidth: CGFloat = 0.20
            let distFromLoop = abs(t - loopCenter)
            let loopBlend = smoothstep(loopWidth, 0, distFromLoop)

            // Inside or near loop region - progress through the loop
            let normalizedT = (t - loopCenter + loopWidth) / (2 * loopWidth)
            let clampedT = max(0, min(1, normalizedT))
            let easedT = smoothstep(0, 1, clampedT)
            let angle = easedT * 2 * .pi

            let loopProgressScale = 1 - loopBlend * 0.75
            let loopBaseT = loopCenter + (t - loopCenter) * loopProgressScale
            let loopBase = baseComponents(at: loopBaseT)
            let waveY = loopBase.y + loopBase.wave

            // Build a loop in the local tangent/normal frame so entry/exit tangents align.
            let baseDY = loopBase.dy
            let tangentLength = sqrt(baseDX * baseDX + baseDY * baseDY)
            guard tangentLength > 0 else {
                return CGPoint(x: loopBase.x, y: waveY)
            }

            let tangent = CGPoint(x: baseDX / tangentLength, y: baseDY / tangentLength)
            let normal = CGPoint(x: -tangent.y, y: tangent.x)

            // Circle offset around the base path, blended in/out to avoid kinks at edges.
            let tangentialOffset = sin(angle) * loopRadius
            let normalOffset = (1 - cos(angle)) * loopRadius * verticalDir
            let loopOffset = CGPoint(
                x: tangent.x * tangentialOffset + normal.x * normalOffset,
                y: tangent.y * tangentialOffset + normal.y * normalOffset
            )

            return CGPoint(x: loopBase.x + loopOffset.x, y: waveY + loopOffset.y)
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

struct WindLinesConfig {
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

    /// Intense burst for blow away effect - many fast wind lines
    static let burst = WindLinesConfig(
        maxLines: 20,
        minSpawnInterval: 0.05,
        spawnChance: 0.5,
        durationRange: 0.4...0.8
    )

    private init(maxLines: Int, minSpawnInterval: Double, spawnChance: Double, durationRange: ClosedRange<Double>) {
        self.maxLines = maxLines
        self.minSpawnInterval = minSpawnInterval
        self.spawnChance = spawnChance
        self.durationRange = durationRange
    }
}

// MARK: - Wind Gust Config

/// Configuration for how gust intensity affects wind line spawning.
/// Used when WindRhythm is provided for synchronized effects.
struct WindGustConfig {
    /// Base spawn chance per frame (at gustIntensity = 0, calm)
    let baseSpawnChance: Double
    /// Maximum spawn chance per frame (at gustIntensity = 1, peak gust)
    let peakSpawnChance: Double
    /// Speed multiplier at peak gust (1.0 = no change, higher = faster lines)
    let peakSpeedMultiplier: Double
    /// Gust intensity threshold above which burst spawning triggers
    let burstThreshold: Double

    init(for windLevel: WindLevel) {
        switch windLevel {
        case .none:
            baseSpawnChance = 0
            peakSpawnChance = 0
            peakSpeedMultiplier = 1.0
            burstThreshold = 2.0 // Never triggers

        case .low:
            baseSpawnChance = 0.01
            peakSpawnChance = 0.10
            peakSpeedMultiplier = 1.3
            burstThreshold = 0.9

        case .medium:
            baseSpawnChance = 0.015
            peakSpawnChance = 0.18
            peakSpeedMultiplier = 1.5
            burstThreshold = 0.85

        case .high:
            baseSpawnChance = 0.02
            peakSpawnChance = 0.30
            peakSpeedMultiplier = 1.8
            burstThreshold = 0.75
        }
    }

    /// Calculate effective spawn chance based on current gust intensity.
    func spawnChance(at gustIntensity: CGFloat) -> Double {
        let t = Double(gustIntensity)
        return baseSpawnChance + (peakSpawnChance - baseSpawnChance) * t
    }

    /// Calculate speed multiplier based on current gust intensity.
    func speedMultiplier(at gustIntensity: CGFloat) -> Double {
        let t = Double(gustIntensity)
        return 1.0 + (peakSpeedMultiplier - 1.0) * t
    }
}

// MARK: - Previews

#Preview("Wind Lines - Low") {
    ZStack {
        Color.gray.opacity(0.2)
        WindLinesView(windLevel: .low, windAreaTop: 0.25, windAreaBottom: 0.50)
    }
}

#Preview("Wind Lines - High") {
    ZStack {
        Color.gray.opacity(0.2)
        WindLinesView(windLevel: .high, windAreaTop: 0.25, windAreaBottom: 0.50)
    }
}

#Preview("Wind Lines - Dark") {
    ZStack {
        Color.black
        WindLinesView(windLevel: .medium, windAreaTop: 0.25, windAreaBottom: 0.50)
    }
    .preferredColorScheme(.dark)
}

#Preview("Wind Lines - Debug Colors") {
    ZStack {
        Color.gray.opacity(0.2)
        WindLinesView(windLevel: .high, debugColors: true, windAreaTop: 0.25, windAreaBottom: 0.50)
    }
}
