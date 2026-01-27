import SwiftUI

struct StatusCard: View {
    let windProgress: CGFloat
    let windLevel: WindLevel
    let preset: WindPreset
    var isBlownAway: Bool = false
    var activeBreak: ActiveBreak? = nil
    var currentWindPoints: Double = 0
    var timeToBlowAway: Double? = nil

    private var isOnBreak: Bool {
        activeBreak != nil
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

            WindPresetInfoSection(preset: preset)
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
            WindProgressBar(progress: Double(windProgress))
        }
        .padding()
    }

    private var progressHeader: some View {
        HStack {
            // Left side: time to blow away (with tilde for approximate)
            VStack(alignment: .leading, spacing: 2) {
                if let minutes = timeToBlowAway, minutes > 0 {
                    Text("~\(formatDuration(Int(ceil(minutes))))")
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

    // MARK: - Break Section

    private func breakSection(_ activeBreak: ActiveBreak) -> some View {
        VStack(spacing: 12) {
            breakInfoRow(activeBreak)

            if let progress = activeBreak.progress {
                WindProgressBar(progress: progress, isPulsing: true)
            }
        }
        .padding()
    }

    private func breakInfoRow(_ activeBreak: ActiveBreak) -> some View {
        HStack {
            // Left side: countdown or elapsed time
            BreakCountdownLabel(activeBreak: activeBreak, formatTime: formatTime)

            Spacer()

            // Right side: break type badge + wind prediction
            VStack(alignment: .trailing, spacing: 6) {
                breakTypeBadge(activeBreak.type)
                windPredictionLabel(activeBreak)
            }
        }
    }

    private func breakTypeBadge(_ type: BreakType) -> some View {
        Text(type.displayName)
            .font(.caption.weight(.medium))
            .foregroundStyle(type.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(type.color.opacity(0.15), in: Capsule())
    }

    @ViewBuilder
    private func windPredictionLabel(_ activeBreak: ActiveBreak) -> some View {
        if activeBreak.type == .free {
            if let minutes = minutesToZeroWind(activeBreak) {
                Text("~\(formatDuration(minutes)) to 0%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("→ \(Int(predictedWindAfter(activeBreak)))% wind")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Break Calculations

    private func predictedWindAfter(_ activeBreak: ActiveBreak) -> Double {
        max(currentWindPoints - activeBreak.windDecreased(for: preset), 0)
    }

    private func minutesToZeroWind(_ activeBreak: ActiveBreak) -> Int? {
        guard activeBreak.type == .free else { return nil }
        guard preset.fallRate > 0 else { return nil }
        let remainingWind = currentWindPoints - activeBreak.windDecreased(for: preset)
        guard remainingWind > 0 else { return 0 }
        return Int(ceil(remainingWind / preset.fallRate))
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
    @State private var alternationTask: Task<Void, Never>?

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
        .onChange(of: isOnBreak) { _, newValue in
            alternationTask?.cancel()
            if newValue {
                startIconAlternation()
            } else {
                showAlternateIcon = false
            }
        }
        .onDisappear {
            alternationTask?.cancel()
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
        alternationTask = Task {
            while !Task.isCancelled && isOnBreak {
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAlternateIcon.toggle()
                }
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

#if DEBUG
#Preview("Normal - Low Wind") {
    StatusCard(
        windProgress: 0.25,
        windLevel: .low,
        preset: .balanced,
        currentWindPoints: 25,
        timeToBlowAway: 7.5
    )
    .padding()
}

#Preview("Normal - High Wind") {
    StatusCard(
        windProgress: 0.85,
        windLevel: .high,
        preset: .balanced,
        currentWindPoints: 85,
        timeToBlowAway: 1.5
    )
    .padding()
}

#Preview("Committed Break") {
    StatusCard(
        windProgress: 0.65,
        windLevel: .medium,
        preset: .balanced,
        activeBreak: .mock(type: .committed, minutesAgo: 10, durationMinutes: 30),
        currentWindPoints: 65
    )
    .padding()
}

#Preview("Free Break - Unlimited") {
    StatusCard(
        windProgress: 0.45,
        windLevel: .low,
        preset: .balanced,
        activeBreak: .unlimitedFree(),
        currentWindPoints: 45
    )
    .padding()
}

#Preview("Blown Away") {
    StatusCard(
        windProgress: 1.0,
        windLevel: .high,
        preset: .balanced,
        isBlownAway: true
    )
    .padding()
}
#endif
