import SwiftUI

struct DynamicStatusCard: View {
    let windProgress: CGFloat
    let windLevel: WindLevel
    var isBlownAway: Bool = false
    var isOnBreak: Bool = false
    var onStartBreak: () -> Void

    private var shouldPulse: Bool {
        windProgress > 0.8 && !isOnBreak
    }

    var body: some View {
        VStack(spacing: 0) {
            weatherSection

            if !isOnBreak {
                Divider()
                    .padding(.horizontal)

                windProgressSection
                    .transition(.move(edge: .top).combined(with: .opacity))
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
            isOnBreak: isOnBreak
        )
        .padding()
    }

    // MARK: - Wind Progress Section

    private var windProgressSection: some View {
        VStack(spacing: 12) {
            progressHeader
            ProgressBarView(progress: Double(windProgress))
            breakButton
        }
        .padding()
    }

    private var progressHeader: some View {
        HStack {
            Text(windLevel.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(windLevel.color)

            Spacer()

            Text("\(Int(windProgress * 100))%")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(windProgress >= 1.0 ? .red : .primary)
        }
    }

    private var breakButton: some View {
        Button(action: onStartBreak) {
            HStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                Text("Calm the Wind")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.cyan, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .pulsingEffect(isActive: shouldPulse)
    }
}

// MARK: - Weather Card Content (without glass background)

struct WeatherCardContent: View {
    let windLevel: WindLevel
    var isBlownAway: Bool = false
    var isOnBreak: Bool = false

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
            return "cloud.bolt.fill"
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
            Image(systemName: windIcon)
                .font(.system(size: 36))
                .foregroundStyle(windColor)
                .symbolEffect(.variableColor.iterative, options: .repeating, value: windLevel)
                .contentTransition(.symbolEffect(.replace))
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

            WindIntensityBars(level: windLevel, isBlownAway: isBlownAway, isOnBreak: isOnBreak)
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

    private func startIconAlternation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if isOnBreak {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAlternateIcon.toggle()
                }
            } else {
                timer.invalidate()
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
        onStartBreak: {}
    )
    .padding()
}

#Preview("Normal - High Wind (Pulsing)") {
    DynamicStatusCard(
        windProgress: 0.85,
        windLevel: .high,
        onStartBreak: {}
    )
    .padding()
}

#Preview("On Break") {
    DynamicStatusCard(
        windProgress: 0.65,
        windLevel: .medium,
        isOnBreak: true,
        onStartBreak: {}
    )
    .padding()
}

#Preview("Blown Away") {
    DynamicStatusCard(
        windProgress: 1.0,
        windLevel: .high,
        isBlownAway: true,
        onStartBreak: {}
    )
    .padding()
}
#endif
