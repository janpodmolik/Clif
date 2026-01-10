import SwiftUI

struct BlockedAppsChart: View {
    let stats: BlockedAppsWeeklyStats
    var onTap: (() -> Void)?

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                headerRow

                chartView

                summaryRow
            }
            .padding()
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(.blue)

            Text("Blocked Apps")
                .font(.headline)

            Spacer()

            Text("Last 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var chartView: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(stats.days.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: 4) {
                    let normalized = stats.maxMinutes > 0
                        ? CGFloat(day.totalMinutes) / CGFloat(stats.maxMinutes)
                        : 0

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: normalized))
                        .frame(height: max(4, normalized * 60))

                    Text(dayLabel(for: index))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    private var summaryRow: some View {
        HStack {
            Label(formatMinutes(stats.averageMinutes), systemImage: "chart.line.downtrend.xyaxis")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("avg")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            Text("Total: \(formatMinutes(stats.totalMinutes))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func dayLabel(for index: Int) -> String {
        guard index < stats.days.count else { return "" }
        let day = stats.days[index].date
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let dayName = formatter.string(from: day)
        return String(dayName.prefix(1))
    }

    private func barColor(for value: CGFloat) -> Color {
        switch value {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
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
#Preview {
    VStack {
        BlockedAppsChart(stats: .mock())

        BlockedAppsChart(stats: .mock(), onTap: {})
    }
    .padding()
}
#endif
