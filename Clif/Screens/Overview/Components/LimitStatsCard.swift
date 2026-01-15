import SwiftUI

struct LimitStatsCard: View {
    let dailyLimitMinutes: Int
    let dailyStats: [DailyUsageStat]
    let totalDays: Int
    var themeColor: Color = .green

    private var totalMinutesUsed: Int {
        dailyStats.reduce(0) { $0 + $1.totalMinutes }
    }

    private var totalLimitMinutes: Int {
        dailyLimitMinutes * totalDays
    }

    private var averageDailyMinutes: Int {
        guard totalDays > 0 else { return 0 }
        return totalMinutesUsed / totalDays
    }

    private var usageProgress: Double {
        guard totalLimitMinutes > 0 else { return 0 }
        return min(Double(totalMinutesUsed) / Double(totalLimitMinutes), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tvůj limit")
                .font(.headline)

            HStack(spacing: 12) {
                limitStatItem(
                    title: "Denní limit",
                    value: formatMinutes(dailyLimitMinutes),
                    icon: "clock.fill"
                )

                limitStatItem(
                    title: "Průměr/den",
                    value: formatMinutes(averageDailyMinutes),
                    icon: "chart.bar.fill"
                )

                limitStatItem(
                    title: "Aktivních dní",
                    value: "\(totalDays)",
                    icon: "calendar"
                )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeColor)
                        .frame(width: geometry.size.width * usageProgress)
                }
            }
            .frame(height: 8)

            Text("Celkem jsi využil **\(formatMinutes(totalMinutesUsed))** z \(formatMinutes(totalLimitMinutes))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func limitStatItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(themeColor)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

#if DEBUG
#Preview("Fully Evolved") {
    let stats = FullUsageStats.mock(days: 14)
    LimitStatsCard(
        dailyLimitMinutes: stats.dailyLimitMinutes,
        dailyStats: stats.days,
        totalDays: 14,
        themeColor: .green
    )
    .padding()
}

#Preview("Blown Away") {
    let stats = FullUsageStats.mock(days: 7)
    LimitStatsCard(
        dailyLimitMinutes: stats.dailyLimitMinutes,
        dailyStats: stats.days,
        totalDays: 7,
        themeColor: .green
    )
    .padding()
}
#endif
