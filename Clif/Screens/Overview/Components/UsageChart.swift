import SwiftUI

struct UsageChart<Stats: UsageStatsProtocol>: View {
    let stats: Stats
    var scrollable: Bool = false
    var showDateLabel: Bool = false
    var themeColor: Color = .green
    var onDayTap: ((DailyUsageStat) -> Void)?

    private let barHeight: CGFloat = 70
    private let barWidth: CGFloat = 36

    private static var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.dateFormat = "d.M."
        return formatter
    }

    private var chartMax: Int {
        max(stats.maxMinutes, stats.dailyLimitMinutes, 1)
    }

    private var totalHeight: CGFloat {
        showDateLabel ? barHeight + 40 : barHeight + 28
    }

    var body: some View {
        if scrollable {
            scrollableContent
        } else {
            fixedContent
        }
    }

    // MARK: - Layouts

    private var fixedContent: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(stats.days) { day in
                dayButton(day: day)
            }
        }
        .frame(height: totalHeight)
    }

    private var scrollableContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(stats.days.enumerated()), id: \.element.id) { index, day in
                        dayButton(day: day)
                            .id(index)
                    }
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .frame(height: totalHeight)
            .onAppear {
                if !stats.days.isEmpty {
                    proxy.scrollTo(stats.days.count - 1, anchor: .trailing)
                }
            }
        }
    }

    // MARK: - Day Button

    private func dayButton(day: DailyUsageStat) -> some View {
        Button {
            onDayTap?(day)
        } label: {
            barColumn(day: day)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bar Column

    private func barColumn(day: DailyUsageStat) -> some View {
        let normalized = chartMax > 0
            ? CGFloat(day.totalMinutes) / CGFloat(chartMax)
            : 0
        let isToday = Calendar.current.isDateInToday(day.date)
        let isOverLimit = day.totalMinutes > stats.dailyLimitMinutes

        return VStack(spacing: 4) {
            Text(formatMinutesShort(day.totalMinutes))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isOverLimit ? .red : .secondary)
                .frame(height: 12)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: barHeight)

                RoundedRectangle(cornerRadius: 6)
                    .fill(barGradient(isToday: isToday, isOverLimit: isOverLimit))
                    .frame(height: max(8, barHeight * normalized))
            }
            .frame(height: barHeight)

            if showDateLabel {
                VStack(spacing: 0) {
                    dayLabel(for: day.date, isToday: isToday)
                    Text(Self.dateFormatter.string(from: day.date))
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            } else {
                dayLabel(for: day.date, isToday: isToday)
            }
        }
        .frame(maxWidth: scrollable ? barWidth : .infinity)
    }

    private func dayLabel(for date: Date, isToday: Bool) -> some View {
        Text(Self.dayFormatter.string(from: date))
            .font(.caption2)
            .fontWeight(isToday ? .semibold : .regular)
            .foregroundStyle(isToday ? .primary : .secondary)
    }

    private func barGradient(isToday: Bool, isOverLimit: Bool) -> LinearGradient {
        if isOverLimit {
            return LinearGradient(
                colors: [.red.opacity(0.9), .red.opacity(0.6)],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        if isToday {
            return LinearGradient(
                colors: [.blue.opacity(0.9), .cyan],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        return LinearGradient(
            colors: [themeColor.opacity(0.9), themeColor.opacity(0.5)],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: - Helpers

    private func formatMinutesShort(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

#Preview("Weekly (fixed)") {
    UsageChart(
        stats: WeeklyUsageStats.mock(dailyLimitMinutes: 90),
        themeColor: .green
    )
    .padding()
}

#Preview("Full (scrollable)") {
    UsageChart(
        stats: FullUsageStats.mock(days: 14, dailyLimitMinutes: 60),
        scrollable: true,
        showDateLabel: true,
        themeColor: .purple
    )
    .padding()
}

#Preview("30 days") {
    UsageChart(
        stats: FullUsageStats.mock(days: 30, dailyLimitMinutes: 90),
        scrollable: true,
        showDateLabel: true,
        themeColor: .green
    )
    .padding()
}
