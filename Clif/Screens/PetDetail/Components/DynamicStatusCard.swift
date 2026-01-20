import SwiftUI

struct DynamicStatusCard: View {
    let windProgress: CGFloat
    let windLevel: WindLevel
    let config: DynamicWindConfig
    var isBlownAway: Bool = false
    var activeBreak: ActiveBreak? = nil
    var currentWindPoints: Double = 0
    var timeToBlowAway: Double? = nil
    var onStartBreak: () -> Void
    var onEndBreak: () -> Void = {}

    private var isOnBreak: Bool {
        activeBreak != nil
    }

    private var shouldPulse: Bool {
        windProgress > 0.8 && !isOnBreak
    }

    var body: some View {
        VStack(spacing: 0) {
            weatherSection

            Divider()
                .padding(.horizontal)

            if let activeBreak {
                breakSection(activeBreak)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            } else {
                windProgressSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: isOnBreak)
    }

    // MARK: - Weather Section

    private var weatherSection: some View {
        WeatherCardContent(
            windLevel: windLevel,
            isBlownAway: isBlownAway,
            isOnBreak: isOnBreak,
            windProgress: windProgress
        )
        .padding()
    }

    // MARK: - Wind Progress Section

    private var windProgressSection: some View {
        VStack(spacing: 12) {
            progressHeader
            ProgressBarView(progress: Double(windProgress))
            calmWindButton
        }
        .padding()
    }

    private var progressHeader: some View {
        HStack {
            // Left side: time to blow away
            VStack(alignment: .leading, spacing: 2) {
                if let minutes = timeToBlowAway, minutes > 0 {
                    Text(formatDuration(Int(ceil(minutes))))
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(windLevel.color)
                    Text("to blow away")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("--:--")
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(.red)
                    Text("blow away!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right side: current wind percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(windProgress * 100))%")
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundStyle(windProgress >= 1.0 ? .red : .primary)
                Text("wind")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var calmWindButton: some View {
        Button(action: onStartBreak) {
            Text("Calm the Wind")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cyan.opacity(0.7), in: Capsule())
        }
        .buttonStyle(.plain)
        .pulsingEffect(isActive: shouldPulse)
    }

    // MARK: - Break Section

    private func breakSection(_ activeBreak: ActiveBreak) -> some View {
        VStack(spacing: 12) {
            breakHeader(activeBreak)

            if let progress = activeBreak.progress {
                ProgressBarView(progress: progress, isPulsing: true)
            }

            breakInfoRow(activeBreak)
            releaseWindButton
        }
        .padding()
    }

    private func breakHeader(_ activeBreak: ActiveBreak) -> some View {
        HStack {
            Text("Calming the Wind")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.cyan)

            Spacer()

            breakTypeBadge(activeBreak.type)
        }
    }

    private func breakTypeBadge(_ type: BreakType) -> some View {
        Text(type.displayName)
            .font(.caption.weight(.medium))
            .foregroundStyle(breakTypeColor(type))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(breakTypeColor(type).opacity(0.15), in: Capsule())
    }

    private func breakTypeColor(_ type: BreakType) -> Color {
        switch type {
        case .free: return .green
        case .committed: return .orange
        case .hardcore: return .red
        }
    }

    private func breakInfoRow(_ activeBreak: ActiveBreak) -> some View {
        HStack {
            // Left side: countdown or elapsed time
            BreakCountdownLabel(activeBreak: activeBreak, formatTime: formatTime)

            Spacer()

            // Right side: wind prediction
            VStack(alignment: .trailing, spacing: 2) {
                if activeBreak.type == .free {
                    if let minutes = minutesToZeroWind(activeBreak) {
                        Text(formatDuration(minutes))
                            .font(.system(.title3, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.green)
                        Text("to wind 0%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(Int(predictedWindAfter(activeBreak)))%")
                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.green)
                    Text("wind after")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var releaseWindButton: some View {
        Button(action: onEndBreak) {
            Text("Release the Wind")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cyan.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Break Calculations

    private func predictedWindAfter(_ activeBreak: ActiveBreak) -> Double {
        max(currentWindPoints - activeBreak.windDecreased(for: config), 0)
    }

    private func minutesToZeroWind(_ activeBreak: ActiveBreak) -> Int? {
        guard activeBreak.type == .free else { return nil }
        let effectiveRate = config.fallRate * activeBreak.type.fallRateMultiplier
        guard effectiveRate > 0 else { return nil }
        let remainingWind = currentWindPoints - activeBreak.windDecreased(for: config)
        guard remainingWind > 0 else { return 0 }
        return Int(ceil(remainingWind / effectiveRate))
    }

    // MARK: - Formatters

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}

// MARK: - Weather Card Content (without glass background)

struct WeatherCardContent: View {
    let windLevel: WindLevel
    var isBlownAway: Bool = false
    var isOnBreak: Bool = false
    var windProgress: CGFloat = 0

    @State private var showAlternateIcon = false

    private var windDescription: String {
        if isBlownAway {
            return "Storm Passed"
        }
        if isOnBreak {
            return "Wind is settling"
        }
        switch windLevel {
        case .none: return "Calm"
        case .low: return "Light Breeze"
        case .medium: return "Moderate Wind"
        case .high: return "Strong Gust"
        }
    }

    private var windIcon: String {
        if isBlownAway {
            return "tornado"
        }
        if isOnBreak && showAlternateIcon {
            return "arrow.down"
        }
        return windLevel.icon
    }

    private var windColor: Color {
        if isBlownAway {
            return .red
        }
        if isOnBreak {
            return .cyan
        }
        return windLevel.color
    }

    private var petStatusText: String {
        if isBlownAway {
            return "The winds were too strong..."
        }
        if isOnBreak {
            return "Taking a moment to breathe"
        }
        switch windLevel {
        case .none: return "Uuumi is thriving"
        case .low: return "Feeling the breeze"
        case .medium: return "Getting a bit stressed"
        case .high: return "Struggling to hold on"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            iconView
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Weather")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(windDescription)
                    .font(.title3.weight(.semibold))

                Text(petStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            WindIntensityBars(level: windLevel, isBlownAway: isBlownAway, isOnBreak: isOnBreak, progress: windProgress)
        }
        .onAppear {
            if isOnBreak {
                startIconAlternation()
            }
        }
        .onChange(of: isOnBreak) { _, newValue in
            if newValue {
                startIconAlternation()
            } else {
                showAlternateIcon = false
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if isBlownAway {
            Image(systemName: windIcon)
                .font(.system(size: 36))
                .foregroundStyle(windColor)
                .symbolEffect(.wiggle, options: .repeating.speed(1.2), isActive: true)
        } else if isOnBreak {
            Image(systemName: windIcon)
                .font(.system(size: 36))
                .foregroundStyle(windColor)
                .contentTransition(.symbolEffect(.replace))
        } else if windLevel == .none {
            Image(systemName: windIcon)
                .font(.system(size: 36))
                .foregroundStyle(windColor)
                .symbolEffect(.breathe, options: .repeating, isActive: true)
        } else {
            Image(systemName: windIcon)
                .font(.system(size: 36))
                .foregroundStyle(windColor)
                .symbolEffect(.wiggle, options: .repeating.speed(wiggleSpeed), isActive: true)
        }
    }

    private var wiggleSpeed: Double {
        switch windLevel {
        case .none: return 0.3
        case .low: return 0.4
        case .medium: return 0.7
        case .high: return 1.0
        }
    }

    private func startIconAlternation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            if isOnBreak {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAlternateIcon.toggle()
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Break Countdown Label

private struct BreakCountdownLabel: View {
    let activeBreak: ActiveBreak
    let formatTime: (TimeInterval) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let remaining = activeBreak.remainingSeconds {
                Text(formatTime(remaining))
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(.cyan)
                    .contentTransition(.identity)
                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(formatTime(activeBreak.elapsedMinutes * 60))
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(.cyan)
                    .contentTransition(.identity)
                Text("elapsed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .modifier(PulsingOpacityModifier())
    }
}

private struct PulsingOpacityModifier: ViewModifier {
    @State private var isHighOpacity = true

    func body(content: Content) -> some View {
        content
            .opacity(isHighOpacity ? 1.0 : 0.6)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isHighOpacity = false
                }
            }
    }
}

// MARK: - Pulsing Effect

private struct PulsingModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? (isPulsing ? 1.0 : 0.7) : 1.0)
            .scaleEffect(isActive ? (isPulsing ? 1.02 : 1.0) : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                if isActive { isPulsing = true }
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}

private extension View {
    func pulsingEffect(isActive: Bool) -> some View {
        modifier(PulsingModifier(isActive: isActive))
    }
}

#if DEBUG
#Preview("Normal - Low Wind") {
    DynamicStatusCard(
        windProgress: 0.25,
        windLevel: .low,
        config: .balanced,
        currentWindPoints: 25,
        timeToBlowAway: 7.5,
        onStartBreak: {}
    )
    .padding()
}

#Preview("Normal - High Wind (Pulsing)") {
    DynamicStatusCard(
        windProgress: 0.85,
        windLevel: .high,
        config: .balanced,
        currentWindPoints: 85,
        timeToBlowAway: 1.5,
        onStartBreak: {}
    )
    .padding()
}

#Preview("Committed Break") {
    DynamicStatusCard(
        windProgress: 0.65,
        windLevel: .medium,
        config: .balanced,
        activeBreak: .mock(type: .committed, minutesAgo: 10, durationMinutes: 30),
        currentWindPoints: 65,
        onStartBreak: {},
        onEndBreak: {}
    )
    .padding()
}

#Preview("Free Break - Unlimited") {
    DynamicStatusCard(
        windProgress: 0.45,
        windLevel: .low,
        config: .balanced,
        activeBreak: .unlimitedFree(),
        currentWindPoints: 45,
        onStartBreak: {},
        onEndBreak: {}
    )
    .padding()
}

#Preview("Hardcore Break") {
    DynamicStatusCard(
        windProgress: 0.80,
        windLevel: .high,
        config: .intense,
        activeBreak: .mock(type: .hardcore, minutesAgo: 5, durationMinutes: 15),
        currentWindPoints: 80,
        onStartBreak: {},
        onEndBreak: {}
    )
    .padding()
}

#Preview("Blown Away") {
    DynamicStatusCard(
        windProgress: 1.0,
        windLevel: .high,
        config: .balanced,
        isBlownAway: true,
        onStartBreak: {}
    )
    .padding()
}
#endif
