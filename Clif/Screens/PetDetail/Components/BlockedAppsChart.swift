import SwiftUI

struct BlockedAppsChart: View {
    let stats: BlockedAppsWeeklyStats
    var onTap: (() -> Void)?

    @State private var selectedDay: BlockedAppsDailyStat?

    private let barHeight: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            chartView

            summaryRow
        }
        .padding()
        .glassCard()
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
        }
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)

            Text("History")
                .font(.headline)

            Spacer()

            Text("Last 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            if onTap != nil {
                Button {
                    onTap?()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chartView: some View {
        HStack(spacing: 8) {
            ForEach(Array(stats.days.enumerated()), id: \.element.id) { index, day in
                Button {
                    selectedDay = day
                } label: {
                    dayColumn(day: day, index: index)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: barHeight + 24) // bar + label
    }

    private func dayColumn(day: BlockedAppsDailyStat, index: Int) -> some View {
        let normalized = stats.maxMinutes > 0
            ? CGFloat(day.totalMinutes) / CGFloat(stats.maxMinutes)
            : 0

        return VStack(spacing: 4) {
            // Container with border that fills based on usage
            ZStack(alignment: .bottom) {
                // Empty container border
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    .frame(height: barHeight)

                // Fill bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(height: max(0, normalized * barHeight))
            }
            .frame(height: barHeight)

            // Day label
            Text(dayLabel(for: index))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
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

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let day: BlockedAppsDailyStat

    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Total Time", systemImage: "clock.fill")
                        Spacer()
                        Text(formatMinutes(day.totalMinutes))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ContentUnavailableView {
                        Label("App Details", systemImage: "app.badge")
                    } description: {
                        Text("Detailed app usage will be available once connected to Family Controls.")
                    }
                }
            }
            .navigationTitle(dateFormatter.string(from: day.date))
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
    NavigationStack {
        PetDetailDebugView()
    }
}

#Preview {
    VStack {
        BlockedAppsChart(stats: .mock())

        BlockedAppsChart(stats: .mock(), onTap: {})
    }
    .padding()
}

#Preview("Day Detail") {
    DayDetailSheet(day: BlockedAppsDailyStat(date: Date(), totalMinutes: 127))
}
#endif
