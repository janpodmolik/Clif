import SwiftUI

struct DailyStatusCard: View {
    let windLevel: WindLevel
    let stat: ScreenTimeStat
    var isBlownAway: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            weatherSection

            Divider()
                .padding(.horizontal)

            screenTimeSection
        }
        .glassCard()
    }

    // MARK: - Weather Section

    private var weatherSection: some View {
        WeatherCardContent(
            windLevel: windLevel,
            isBlownAway: isBlownAway,
            isOnBreak: false
        )
        .padding()
    }

    // MARK: - Screen Time Section

    private var screenTimeSection: some View {
        VStack(spacing: 12) {
            screenTimeHeader
            ProgressBarView(progress: stat.progress ?? 0)
        }
        .padding()
    }

    private var screenTimeHeader: some View {
        HStack {
            // Left side: used time
            VStack(alignment: .leading, spacing: 2) {
                Text(formatMinutes(stat.usedMinutes))
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(stat.tintColor)
                Text("used today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side: limit
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatMinutes(stat.limitMinutes))
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("daily limit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        }
        return String(format: "0:%02d", mins)
    }
}

#if DEBUG
#Preview("Low Usage") {
    DailyStatusCard(
        windLevel: .low,
        stat: ScreenTimeStat(usedMinutes: 30, limitMinutes: 120)
    )
    .padding()
}

#Preview("Medium Usage") {
    DailyStatusCard(
        windLevel: .medium,
        stat: ScreenTimeStat(usedMinutes: 90, limitMinutes: 120)
    )
    .padding()
}

#Preview("High Usage") {
    DailyStatusCard(
        windLevel: .high,
        stat: ScreenTimeStat(usedMinutes: 110, limitMinutes: 120)
    )
    .padding()
}

#Preview("Over Limit") {
    DailyStatusCard(
        windLevel: .high,
        stat: ScreenTimeStat(usedMinutes: 150, limitMinutes: 120),
        isBlownAway: true
    )
    .padding()
}
#endif
