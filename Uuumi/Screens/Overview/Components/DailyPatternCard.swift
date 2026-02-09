import Charts
import SwiftUI

/// Card showing average hourly usage pattern across all tracked days.
struct DailyPatternCard: View {
    let aggregate: HourlyAggregate

    @State private var selectedHour: Int?

    private var averages: [Double] { aggregate.hourlyAverages }
    private var peakHour: Int? { aggregate.peakHour }

    /// The hour shown in the footer — selected or peak.
    private var displayedHour: Int? { selectedHour ?? peakHour }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
                .padding(.horizontal)

            chart
                .frame(height: 120)
                .padding(.horizontal)

            if let hour = displayedHour {
                footerRow(hour: hour)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.15), value: displayedHour)
            }
        }
        .padding(.vertical)
        .glassCard()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.secondary)

            Text("Daily Pattern")
                .font(.headline)

            Spacer()

            Text("\(aggregate.dayCount) days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(0..<24, id: \.self) { hour in
                BarMark(
                    x: .value("Hour", hour),
                    y: .value("Minutes", averages[hour])
                )
                .foregroundStyle(barColor(for: hour))
                .cornerRadius(2)
            }

            if let selected = selectedHour {
                RuleMark(x: .value("Selected", selected))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                        annotationLabel(for: selected)
                    }
            }
        }
        .chartXSelection(value: $selectedHour)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(formatHour(hour))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXScale(domain: 0...23)
    }

    // MARK: - Annotation

    private func annotationLabel(for hour: Int) -> some View {
        VStack(spacing: 2) {
            Text(formatHour(hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(averages[hour]))m")
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Footer

    private func footerRow(hour: Int) -> some View {
        HStack(spacing: 4) {
            if selectedHour == nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("Peak hour: \(formatHour(hour))–\(formatHour((hour + 1) % 24))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("\(formatHour(hour))–\(formatHour((hour + 1) % 24)): avg \(Int(averages[hour]))m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentTransition(.numericText())
    }

    // MARK: - Helpers

    private func barColor(for hour: Int) -> Color {
        if let selected = selectedHour {
            return hour == selected ? .blue : .blue.opacity(0.2)
        }
        return hour == peakHour ? .orange : .blue.opacity(0.6)
    }

    private func formatHour(_ hour: Int) -> String {
        "\(hour):00"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Data") {
    DailyPatternCard(aggregate: .mock())
        .padding()
}

#Preview("Minimal Data") {
    DailyPatternCard(aggregate: .mock(days: 2))
        .padding()
}
#endif
