import SwiftUI

struct ScreenTimeOverviewCard: View {
    let stats: BlockedAppsWeeklyStats

    private var maxMinutes: Int {
        stats.days.map(\.totalMinutes).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Čas u obrazovky")
                .font(.headline)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(formatMinutes(stats.totalMinutes))
                    .font(.system(size: 34, weight: .bold))
                Text("za posledních 7 dní")
                    .foregroundStyle(.secondary)
            }

            chartView

            HStack {
                Text("Průměr/den")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatMinutes(stats.averageMinutes))
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .padding(18)
        .glassCard()
    }

    private var chartView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(stats.days.enumerated()), id: \.element.id) { index, day in
                barColumn(day: day, index: index)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
    }

    private func barColumn(day: BlockedAppsDailyStat, index: Int) -> some View {
        let normalized = maxMinutes > 0
            ? CGFloat(day.totalMinutes) / CGFloat(maxMinutes)
            : 0

        return VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 18, height: 80)

                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [.green.opacity(0.9), .mint],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 18, height: max(12, 80 * normalized))
            }

            Text(dayLabel(for: day.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

#Preview {
    ScreenTimeOverviewCard(stats: .mock())
        .padding()
}
