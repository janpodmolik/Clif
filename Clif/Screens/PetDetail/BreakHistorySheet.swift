import SwiftUI

/// Detail sheet showing full break history and statistics.
struct BreakHistorySheet: View {
    let breakHistory: [CompletedBreak]

    @Environment(\.dismiss) private var dismiss
    @State private var chartStyle: ChartStyle = .pie

    private enum ChartStyle: String, CaseIterable {
        case pie = "Pie"
        case bar = "Bar"
    }

    // MARK: - Computed Stats

    private var totalBreaks: Int {
        breakHistory.count
    }

    private var totalMinutes: Double {
        breakHistory.reduce(0) { $0 + $1.durationMinutes }
    }

    private var averageMinutes: Double {
        guard totalBreaks > 0 else { return 0 }
        return totalMinutes / Double(totalBreaks)
    }

    private var longestBreak: Double {
        breakHistory.map(\.durationMinutes).max() ?? 0
    }

    private var breaksByType: [(type: BreakType, count: Int, minutes: Double)] {
        BreakType.allCases.compactMap { type in
            let filtered = breakHistory.filter { $0.type == type }
            let count = filtered.count
            let minutes = filtered.reduce(0) { $0 + $1.durationMinutes }
            return count > 0 ? (type, count, minutes) : nil
        }
    }

    private var sortedBreaks: [CompletedBreak] {
        breakHistory.sorted { $0.startedAt > $1.startedAt }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if breakHistory.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 16) {
                        overviewSection
                        chartsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Break History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No breaks yet")
                .font(.headline)
            Text("Take a break to calm the wind")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    private var overviewSection: some View {
        VStack(spacing: 0) {
            statRow(label: "Total Breaks", value: "\(totalBreaks)")
            Divider()
            statRow(label: "Total Time", value: formatMinutes(totalMinutes))
            Divider()
            statRow(label: "Average", value: formatMinutes(averageMinutes))
            Divider()
            statRow(label: "Longest", value: formatMinutes(longestBreak))
        }
        .glassCard()
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var chartsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("By Type")
                    .font(.headline)

                Spacer()

                Picker("Chart Style", selection: $chartStyle) {
                    ForEach(ChartStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // Charts
            switch chartStyle {
            case .pie:
                pieChartsView
            case .bar:
                barChartsView
            }

            Divider()

            // Shared legend
            legendView
        }
        .padding()
        .glassCard()
    }

    private var pieChartsView: some View {
        HStack(spacing: 24) {
            pieColumn(
                data: breaksByType.map { ($0.type, Double($0.count)) },
                centerLabel: "\(totalBreaks)",
                centerSubLabel: "breaks",
                title: "Count"
            )

            pieColumn(
                data: breaksByType.map { ($0.type, $0.minutes) },
                centerLabel: formatMinutesShort(totalMinutes),
                centerSubLabel: "total",
                title: "Time"
            )
        }
    }

    private var barChartsView: some View {
        HStack(spacing: 24) {
            barColumn(
                data: breaksByType.map { ($0.type, Double($0.count)) },
                title: "Count"
            )

            barColumn(
                data: breaksByType.map { ($0.type, $0.minutes) },
                title: "Time"
            )
        }
    }

    private var legendView: some View {
        VStack(spacing: 6) {
            // Header row
            HStack {
                Text("Type")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("Count")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 40, alignment: .trailing)

                Text("Time")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 50, alignment: .trailing)
            }

            // Data rows
            ForEach(breaksByType, id: \.type) { item in
                HStack {
                    Circle()
                        .fill(item.type.color)
                        .frame(width: 8, height: 8)

                    Text(item.type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                        .frame(width: 40, alignment: .trailing)

                    Text(formatMinutes(item.minutes))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Subviews

    private func pieColumn(
        data: [(type: BreakType, value: Double)],
        centerLabel: String,
        centerSubLabel: String,
        title: String
    ) -> some View {
        VStack(spacing: 8) {
            BreakPieChart(
                data: data,
                centerLabel: centerLabel,
                centerSubLabel: centerSubLabel
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }

    private func barColumn(
        data: [(type: BreakType, value: Double)],
        title: String
    ) -> some View {
        let maxValue = data.map(\.value).max() ?? 1

        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.type) { item in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.type.color)
                        .frame(height: max(8, CGFloat(item.value / maxValue) * 100))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
            )

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    private func formatMinutesShort(_ minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            return "\(hours)h"
        }
        return "\(totalMinutes)m"
    }
}

// MARK: - Pie Chart

private struct BreakPieChart: View {
    let data: [(type: BreakType, value: Double)]
    let centerLabel: String
    let centerSubLabel: String

    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 4
                let innerRadius = radius * 0.6

                var startAngle: Angle = .degrees(-90)

                for item in data {
                    let sweepAngle = Angle.degrees(360 * (item.value / total))

                    let path = Path { p in
                        p.move(to: center)
                        p.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: startAngle + sweepAngle,
                            clockwise: false
                        )
                        p.closeSubpath()
                    }

                    context.fill(path, with: .color(item.type.color))
                    startAngle += sweepAngle
                }

                // Inner circle for donut effect
                let innerPath = Path(ellipseIn: CGRect(
                    x: center.x - innerRadius,
                    y: center.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                ))
                context.blendMode = .destinationOut
                context.fill(innerPath, with: .color(.black))
            }
            .compositingGroup()

            // Center labels
            VStack(spacing: 0) {
                Text(centerLabel)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                Text(centerSubLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - BreakType Color Extension

private extension BreakType {
    var color: Color {
        switch self {
        case .free: return .cyan
        case .committed: return .blue
        case .hardcore: return .indigo
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Breaks") {
    BreakHistorySheet(breakHistory: CompletedBreak.mockList())
}

#Preview("Empty") {
    BreakHistorySheet(breakHistory: [])
}

#Preview("Many Breaks") {
    BreakHistorySheet(breakHistory: CompletedBreak.mockList(count: 8))
}
#endif
