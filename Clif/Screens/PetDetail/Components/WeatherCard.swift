import SwiftUI

struct WeatherCard: View {
    let windLevel: WindLevel
    var isBlownAway: Bool = false

    private var windDescription: String {
        if isBlownAway {
            return "Storm Passed"
        }
        switch windLevel {
        case .none: return "Calm"
        case .low: return "Light Breeze"
        case .medium: return "Moderate Wind"
        case .high: return "Strong Gust"
        }
    }

    private var windIcon: String {
        isBlownAway ? "cloud.bolt.fill" : windLevel.icon
    }

    private var windColor: Color {
        isBlownAway ? .red : windLevel.color
    }

    private var petStatusText: String {
        if isBlownAway {
            return "The winds were too strong..."
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

            WindIntensityBars(level: windLevel, isBlownAway: isBlownAway)
        }
        .padding()
        .glassCard()
    }
}

struct WindIntensityBars: View {
    let level: WindLevel
    var isBlownAway: Bool = false

    private var activeBarCount: Int {
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
            return .purple
        }
        switch level {
        case .none: return .green
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < activeBarCount ? barColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: CGFloat(10 + index * 6))
            }
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
#endif
