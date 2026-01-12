import SwiftUI

struct TrendMiniChart: View {
    let stats: FullUsageStats

    private let chartHeight: CGFloat = 40

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.dateFormat = "d.M."
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            sparkline
            footerRow
        }
        .padding()
        .glassCard()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Vývoj")
                .font(.headline)

            Spacer()

            trendBadge
        }
    }

    private var trendBadge: some View {
        HStack(spacing: 4) {
            Text(stats.trend.displayName)
            Image(systemName: stats.trend.icon)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(trendColor)
    }

    private var trendColor: Color {
        switch stats.trend {
        case .improving: .green
        case .stable: .secondary
        case .worsening: .red
        }
    }

    // MARK: - Sparkline

    private var sparkline: some View {
        let values = stats.normalizedValues()

        return GeometryReader { geo in
            Path { path in
                guard values.count > 1 else { return }

                let stepX = geo.size.width / CGFloat(values.count - 1)
                let height = geo.size.height

                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (value * height * 0.9) - (height * 0.05)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: chartHeight)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            if let first = stats.days.first, let last = stats.days.last {
                Text("\(Self.dateFormatter.string(from: first.date)) - \(Self.dateFormatter.string(from: last.date))")
            }

            Spacer()

            Text("Ø \(formatMinutes(stats.averageMinutes))/den")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

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
#Preview("Improving") {
    TrendMiniChart(stats: .mock(days: 14, dailyLimitMinutes: 60))
        .padding()
}

#Preview("30 days") {
    TrendMiniChart(stats: .mock(days: 30, dailyLimitMinutes: 90))
        .padding()
}
#endif
