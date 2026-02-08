import Charts
import SwiftUI

/// Wind timeline chart showing wind points progression throughout the day.
/// Uses SnapshotEvent data to plot usageThreshold events over time.
struct WindTimelineChart: View {
    let snapshots: [SnapshotEvent]
    let limitMinutes: Int

    @State private var selectedPoint: ChartDataPoint?

    private var dataPoints: [ChartDataPoint] {
        snapshots
            .compactMap { event -> ChartDataPoint? in
                switch event.eventType {
                case .usageThreshold(let cumulativeSeconds):
                    return ChartDataPoint(
                        timestamp: event.timestamp,
                        windPoints: event.windPoints,
                        cumulativeSeconds: cumulativeSeconds,
                        isBreakEvent: false
                    )
                case .breakStarted, .breakEnded:
                    return ChartDataPoint(
                        timestamp: event.timestamp,
                        windPoints: event.windPoints,
                        cumulativeSeconds: nil,
                        isBreakEvent: true
                    )
                default:
                    return nil
                }
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var hasData: Bool {
        !dataPoints.isEmpty
    }

    private var timeRange: ClosedRange<Date>? {
        guard let first = dataPoints.first?.timestamp,
              let last = dataPoints.last?.timestamp else {
            return nil
        }
        // Add 30 min padding on each side
        let padding: TimeInterval = 30 * 60
        return first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Průběh větru")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            if hasData {
                chartView
                    .frame(maxHeight: .infinity)
            } else {
                emptyState
            }
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Čas", point.timestamp),
                    y: .value("Vítr", point.windPoints)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(windGradient)

                AreaMark(
                    x: .value("Čas", point.timestamp),
                    y: .value("Vítr", point.windPoints)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(areaGradient)
            }

            // Limit line at 100%
            RuleMark(y: .value("Limit", 100))
                .foregroundStyle(.red.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.7))
                }

            // Selected point indicator
            if let selected = selectedPoint {
                PointMark(
                    x: .value("Čas", selected.timestamp),
                    y: .value("Vítr", selected.windPoints)
                )
                .foregroundStyle(windColor(for: selected.windPoints))
                .symbolSize(100)

                RuleMark(x: .value("Čas", selected.timestamp))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYScale(domain: 0...max(110, (dataPoints.map(\.windPoints).max() ?? 100) + 10))
        .chartXScale(domain: timeRange ?? Date()...Date())
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelectedPoint(at: value.location, proxy: proxy, geo: geo)
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .overlay(alignment: .top) {
            if let selected = selectedPoint {
                tooltipView(for: selected)
                    .transition(.opacity)
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("Žádná data o větru")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    private func tooltipView(for point: ChartDataPoint) -> some View {
        VStack(spacing: 2) {
            Text(formatTime(point.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(point.windPoints))%")
                .font(.caption.bold())
                .foregroundStyle(windColor(for: point.windPoints))
            if let seconds = point.cumulativeSeconds {
                Text(formatMinutes(seconds / 60))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if point.isBreakEvent {
                Text("Break")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private func updateSelectedPoint(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let xPosition = location.x - geo[plotFrame].origin.x

        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find closest data point
        let closest = dataPoints.min(by: {
            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
        })

        selectedPoint = closest
    }

    // MARK: - Styling

    private var windGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                .green.opacity(0.3),
                .yellow.opacity(0.2),
                .orange.opacity(0.1),
                .clear
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func windColor(for points: Double) -> Color {
        switch points {
        case ..<25: .green
        case 25..<50: .yellow
        case 50..<75: .orange
        default: .red
        }
    }

    // MARK: - Formatting

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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

// MARK: - Chart Data Point

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let windPoints: Double
    let cumulativeSeconds: Int?
    let isBreakEvent: Bool
}

// MARK: - Preview

#if DEBUG
#Preview("With Data") {
    let petId = UUID()
    let today = Calendar.current.startOfDay(for: Date())
    let snapshots: [SnapshotEvent] = [
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(8 * 3600), windPoints: 10, eventType: .usageThreshold(cumulativeSeconds: 300)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(9 * 3600), windPoints: 25, eventType: .usageThreshold(cumulativeSeconds: 750)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(10 * 3600), windPoints: 35, eventType: .usageThreshold(cumulativeSeconds: 1050)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(12 * 3600), windPoints: 50, eventType: .usageThreshold(cumulativeSeconds: 1500)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(14 * 3600), windPoints: 65, eventType: .usageThreshold(cumulativeSeconds: 1950)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(16 * 3600), windPoints: 80, eventType: .usageThreshold(cumulativeSeconds: 2400)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(18 * 3600), windPoints: 95, eventType: .usageThreshold(cumulativeSeconds: 2850))
    ]

    WindTimelineChart(snapshots: snapshots, limitMinutes: 60)
        .padding()
        .glassCard()
        .padding()
}

#Preview("With Break") {
    let petId = UUID()
    let today = Calendar.current.startOfDay(for: Date())
    let snapshots: [SnapshotEvent] = [
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(8 * 3600), windPoints: 10, eventType: .usageThreshold(cumulativeSeconds: 300)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(10 * 3600), windPoints: 35, eventType: .usageThreshold(cumulativeSeconds: 1050)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(12 * 3600), windPoints: 55, eventType: .usageThreshold(cumulativeSeconds: 1650)),
        // Break started at 55%
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(12.5 * 3600), windPoints: 55, eventType: .breakStarted(type: .committed(plannedMinutes: 30))),
        // Break ended at 40% (30 min break with fallRate ~0.5/min)
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(13 * 3600), windPoints: 40, eventType: .breakEnded(actualMinutes: 30, success: true)),
        // Usage continues
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(15 * 3600), windPoints: 60, eventType: .usageThreshold(cumulativeSeconds: 2250)),
        SnapshotEvent(petId: petId, timestamp: today.addingTimeInterval(17 * 3600), windPoints: 80, eventType: .usageThreshold(cumulativeSeconds: 2850))
    ]

    WindTimelineChart(snapshots: snapshots, limitMinutes: 60)
        .padding()
        .glassCard()
        .padding()
}

#Preview("Empty") {
    WindTimelineChart(snapshots: [], limitMinutes: 60)
        .padding()
        .glassCard()
        .padding()
}
#endif
