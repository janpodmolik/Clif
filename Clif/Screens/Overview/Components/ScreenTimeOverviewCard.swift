import FamilyControls
import ManagedSettings
import SwiftUI

struct ScreenTimeOverviewCard: View {
    let stats: BlockedAppsWeeklyStats
    var applicationTokens: Set<ApplicationToken> = []
    var categoryTokens: Set<ActivityCategoryToken> = []

    @State private var selectedDay: BlockedAppsDailyStat?

    private var maxMinutes: Int {
        stats.days.map(\.totalMinutes).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            totalTimeSection

            if !applicationTokens.isEmpty || !categoryTokens.isEmpty {
                BlockedAppsPreview(
                    applicationTokens: applicationTokens,
                    categoryTokens: categoryTokens
                )
            }

            chartSection

            quickStatsRow
        }
        .padding(18)
        .glassCard()
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Čas u obrazovky")
                .font(.headline)

            Spacer()

            if let trend = stats.trendPercentage {
                TrendBadge(percentage: trend)
            }
        }
    }

    // MARK: - Total Time

    private var totalTimeSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(formatMinutes(stats.totalMinutes))
                .font(.system(size: 34, weight: .bold))
            Text("za posledních 7 dní")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(stats.days.enumerated()), id: \.element.id) { _, day in
                Button {
                    selectedDay = day
                } label: {
                    barColumn(day: day)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    private func barColumn(day: BlockedAppsDailyStat) -> some View {
        let normalized = maxMinutes > 0
            ? CGFloat(day.totalMinutes) / CGFloat(maxMinutes)
            : 0
        let isToday = Calendar.current.isDateInToday(day.date)

        return VStack(spacing: 4) {
            Text(formatMinutesShort(day.totalMinutes))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(height: 12)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 70)

                RoundedRectangle(cornerRadius: 6)
                    .fill(barGradient(isToday: isToday))
                    .frame(height: max(8, 70 * normalized))
            }
            .frame(height: 70)

            Text(dayLabel(for: day.date))
                .font(.caption2)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func barGradient(isToday: Bool) -> LinearGradient {
        if isToday {
            return LinearGradient(
                colors: [.blue.opacity(0.9), .cyan],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        return LinearGradient(
            colors: [.green.opacity(0.9), .mint],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack {
            Text("Průměrně \(formatMinutes(stats.averageMinutes)) na den")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let worst = stats.worstDay {
                WorstDayBadge(dayName: dayLabel(for: worst.date))
            }
        }
    }

    // MARK: - Helpers

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

    private func formatMinutesShort(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

#Preview {
    ScreenTimeOverviewCard(stats: BlockedAppsWeeklyStats.mock())
        .padding()
}
