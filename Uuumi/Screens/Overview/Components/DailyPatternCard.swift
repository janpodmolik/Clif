import Charts
import SwiftUI

struct DailyPatternCard: View {
    let aggregate: HourlyAggregate
    @Binding var daysLimit: Int?

    @Environment(StoreManager.self) private var storeManager
    @State private var selectedHour: Int?
    @State private var showInfo = false
    @State private var showPremiumSheet = false

    private var averages: [Double] { aggregate.hourlyAverages }
    private var peakHour: Int? { aggregate.peakHour }
    private var displayedHour: Int? { selectedHour ?? peakHour }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            summarySection
            chart
                .frame(height: 160)
            if let hour = displayedHour {
                statsRow(hour: hour)
                    .animation(.easeInOut(duration: 0.15), value: displayedHour)
            }
        }
        .padding(18)
        .glassCard()
        .onChange(of: daysLimit) { selectedHour = nil }
        .onAppear {
            if !storeManager.isPremium {
                daysLimit = 7
            }
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet(source: "daily_pattern")
        }
        .alert("Daily pattern", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The chart shows average screen time in blocked apps throughout the day. Data is averaged over \(aggregate.dayCount) days. Tap a bar to see details for a specific hour.")
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.secondary)

            Text("Daily pattern")
                .font(.headline)

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            daysMenu
        }
    }

    /// Wraps `Int?` so Picker can use it as a tag.
    private enum DaysOption: Hashable, CaseIterable {
        case days7, days14, days30, all

        var limit: Int? {
            switch self {
            case .days7: 7
            case .days14: 14
            case .days30: 30
            case .all: nil
            }
        }

        /// Minimum number of tracked days required to show this option.
        var minDays: Int {
            switch self {
            case .days7: 7
            case .days14: 14
            case .days30: 30
            case .all: 0
            }
        }

        var label: String {
            switch self {
            case .days7: "7 days"
            case .days14: "14 days"
            case .days30: "30 days"
            case .all: "All"
            }
        }

        init(limit: Int?) {
            switch limit {
            case 7: self = .days7
            case 14: self = .days14
            case 30: self = .days30
            default: self = .all
            }
        }
    }

    private var availableOptions: [DaysOption] {
        DaysOption.allCases.filter { $0.minDays <= aggregate.dayCount }
    }

    private var selectedOption: Binding<DaysOption> {
        Binding(
            get: { DaysOption(limit: daysLimit) },
            set: { daysLimit = $0.limit }
        )
    }

    @ViewBuilder
    private var daysMenu: some View {
        let options = availableOptions
        if storeManager.isPremium {
            if options.count > 1 {
                Picker("Period", selection: selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.1), in: Capsule())
            }
        } else if options.count > 1 {
            HStack(spacing: 0) {
                Text("7 days")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 6))

                Button {
                    showPremiumSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("More")
                    }
                    .foregroundStyle(Color("PremiumGold"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                }
            }
            .font(.caption.weight(.medium))
            .fixedSize()
            .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 7))
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formatMinutesLong(aggregate.totalDailyAverage))
                .font(.system(size: 28, weight: .bold))
            Text("average daily time")
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
                    y: .value("Minutes", averages[hour]),
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
                        Text(formatHour(hour))
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

    // MARK: - Stats Row

    private func statsRow(hour: Int) -> some View {
        HStack(spacing: 12) {
            if selectedHour == nil {
                statIcon(systemName: "flame.fill", color: .orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(formatHour(hour))–\(formatHour((hour + 1) % 24))")
                        .font(.subheadline.weight(.semibold))
                    Text("busiest hour")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(averages[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("average")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                statIcon(systemName: "hand.tap.fill", color: .blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(formatHour(hour))–\(formatHour((hour + 1) % 24))")
                        .font(.subheadline.weight(.semibold))
                    Text("selected hour")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(averages[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text("average")
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

    private func formatHour(_ hour: Int) -> String {
        "\(hour):00"
    }

    private func formatMinutesLong(_ minutes: Double) -> String {
        let total = Int(minutes)
        let h = total / 60
        let m = total % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With data") {
    DailyPatternCard(aggregate: .mock(), daysLimit: .constant(14))
        .padding()
        .environment(StoreManager.mock())
}

#Preview("Minimum data") {
    DailyPatternCard(aggregate: .mock(days: 2), daysLimit: .constant(nil))
        .padding()
        .environment(StoreManager.mock())
}
#endif
