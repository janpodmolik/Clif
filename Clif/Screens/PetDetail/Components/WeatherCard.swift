import SwiftUI

struct WeatherCard: View {
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
        .padding()
        .glassCard()
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

struct WindIntensityBars: View {
    let level: WindLevel
    var isBlownAway: Bool = false
    var isOnBreak: Bool = false

    @State private var animatedBarCount: Int = 0
    @State private var isAnimating = false

    private var baseBarCount: Int {
        if isBlownAway {
            return 4
        }
        switch level {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 4
        }
    }

    private var barColor: Color {
        if isBlownAway {
            return .red
        }
        if isOnBreak {
            return .cyan
        }
        switch level {
        case .none: return .green
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var displayBarCount: Int {
        isOnBreak ? animatedBarCount : baseBarCount
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < displayBarCount ? barColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: CGFloat(10 + index * 6))
            }
        }
        .onAppear {
            animatedBarCount = baseBarCount
            if isOnBreak {
                startBarAnimation()
            }
        }
        .onChange(of: isOnBreak) { _, newValue in
            if newValue {
                animatedBarCount = baseBarCount
                startBarAnimation()
            } else {
                isAnimating = false
                animatedBarCount = baseBarCount
            }
        }
    }

    private func startBarAnimation() {
        isAnimating = true
        animateDecrease()
    }

    private func animateDecrease() {
        guard isAnimating, isOnBreak, baseBarCount > 0 else { return }

        // Decrease by 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard isAnimating, isOnBreak else { return }

            withAnimation(.easeInOut(duration: 0.4)) {
                animatedBarCount = baseBarCount - 1
            }

            // Return to base after short delay
            animateIncrease()
        }
    }

    private func animateIncrease() {
        guard isAnimating, isOnBreak else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard isAnimating, isOnBreak else { return }

            withAnimation(.easeInOut(duration: 0.4)) {
                animatedBarCount = baseBarCount
            }

            // Start cycle again
            animateDecrease()
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        WeatherCard(windLevel: .none)
        WeatherCard(windLevel: .low)
        WeatherCard(windLevel: .medium)
        WeatherCard(windLevel: .high)
    }
    .padding()
}

#Preview("Blown Away") {
    WeatherCard(windLevel: .high, isBlownAway: true)
        .padding()
}

#Preview("On Break") {
    WeatherCard(windLevel: .medium, isOnBreak: true)
        .padding()
}
#endif
