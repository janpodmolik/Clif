import SwiftUI

struct PetWeeklyChart: View {
    let stats: BlockedAppsWeeklyStats
    let limitMinutes: Int?
    var themeColor: Color = .green
    var onDayTap: ((BlockedAppsDailyStat) -> Void)?

    private let barHeight: CGFloat = 70

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    private var chartMax: Int {
        max(stats.maxMinutes, limitMinutes ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(stats.days.enumerated()), id: \.element.id) { _, day in
                Button {
                    onDayTap?(day)
                } label: {
                    barColumn(day: day)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: barHeight + 28)
    }

    // MARK: - Bar Column

    private func barColumn(day: BlockedAppsDailyStat) -> some View {
        let normalized = chartMax > 0
            ? CGFloat(day.totalMinutes) / CGFloat(chartMax)
            : 0
        let isToday = Calendar.current.isDateInToday(day.date)
        let isOverLimit = limitMinutes.map { day.totalMinutes > $0 } ?? false

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

            Text(dayLabel(for: day.date))
                .font(.caption2)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
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

    private func dayLabel(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
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
    PetWeeklyChart(
        stats: .mock(),
        limitMinutes: 90,
        themeColor: .green
    )
    .padding()
}
