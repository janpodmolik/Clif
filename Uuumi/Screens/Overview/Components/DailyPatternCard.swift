import Charts
import SwiftUI

struct DailyPatternCard: View {
    let aggregate: HourlyAggregate
    @Binding var daysLimit: Int?

    @State private var selectedHour: Int?
    @State private var showInfo = false

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
        .alert("Denní vzor", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Graf zobrazuje průměrný čas u obrazovky v blokovaných aplikacích v průběhu dne. Data jsou průměrována za \(aggregate.dayCount) dní. Klepnutím na sloupec zobrazíš detail konkrétní hodiny.")
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.secondary)

            Text("Denní vzor")
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
            case .days7: "7 dní"
            case .days14: "14 dní"
            case .days30: "30 dní"
            case .all: "Vše"
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
        if options.count > 1 {
            Picker("Období", selection: selectedOption) {
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
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formatMinutesLong(aggregate.totalDailyAverage))
                .font(.system(size: 28, weight: .bold))
            Text("průměrný denní čas")
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
                    Text("nejvytíženější hodina")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(averages[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("průměr")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                statIcon(systemName: "hand.tap.fill", color: .blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(formatHour(hour))–\(formatHour((hour + 1) % 24))")
                        .font(.subheadline.weight(.semibold))
                    Text("vybraná hodina")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(averages[hour]))m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text("průměr")
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
#Preview("S daty") {
    DailyPatternCard(aggregate: .mock(), daysLimit: .constant(14))
        .padding()
}

#Preview("Minimum dat") {
    DailyPatternCard(aggregate: .mock(days: 2), daysLimit: .constant(nil))
        .padding()
}
#endif
