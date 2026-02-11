import Charts
import SwiftUI

/// Hourly bar chart for a single day.
/// Fallback for WindTimelineChart when raw snapshots are not available (e.g. after restore).
struct DayHourlyChart: View {
    let breakdown: DailyHourlyBreakdown

    @State private var selectedHour: Int?

    private var peakHour: Int? { breakdown.peakHour }
    private var displayedHour: Int? { selectedHour ?? peakHour }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aktivita v průběhu dne")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            chart
                .frame(height: 160)

            if let hour = displayedHour {
                statsRow(hour: hour)
                    .animation(.easeInOut(duration: 0.15), value: displayedHour)
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(0..<24, id: \.self) { hour in
                BarMark(
                    x: .value("Hodina", hour),
                    y: .value("Minuty", breakdown.hourlyMinutes[hour]),
                    width: .fixed(8)
                )
                .foregroundStyle(barColor(for: hour))
                .cornerRadius(3)
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
                        Text("\(hour):00")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
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
            Text("\(hour):00")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(breakdown.hourlyMinutes[hour]))m")
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Stats Row

    private func statsRow(hour: Int) -> some View {
        HStack(spacing: 12) {
            if selectedHour == nil {
                statIcon(systemName: "flame.fill", color: .orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(hour):00–\((hour + 1) % 24):00")
                        .font(.subheadline.weight(.semibold))
                    Text("nejvytíženější hodina")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(breakdown.hourlyMinutes[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("celkem")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                statIcon(systemName: "hand.tap.fill", color: .blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(hour):00–\((hour + 1) % 24):00")
                        .font(.subheadline.weight(.semibold))
                    Text("vybraná hodina")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(breakdown.hourlyMinutes[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text("celkem")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentTransition(.numericText())
    }

    private func statIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.caption)
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func barColor(for hour: Int) -> Color {
        if let selected = selectedHour {
            return hour == selected ? .blue : .blue.opacity(0.2)
        }
        return hour == peakHour ? .orange : .blue.opacity(0.6)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With data") {
    DayHourlyChart(breakdown: DailyHourlyBreakdown(
        date: "2025-01-15",
        hourlyMinutes: [
            0, 0, 0, 0, 0, 0,      // 0-5
            2, 5, 15, 20, 8, 3,     // 6-11
            1, 5, 10, 12, 18, 25,   // 12-17
            30, 20, 10, 5, 2, 0     // 18-23
        ]
    ))
    .padding()
    .glassCard()
    .padding()
}
#endif
