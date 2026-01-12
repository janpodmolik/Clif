import SwiftUI

enum UsageViewMode: String, CaseIterable {
    case week = "7 dní"
    case all = "Vše"
}

struct UsageCard: View {
    let stats: FullUsageStats

    @State private var viewMode: UsageViewMode = .week
    @State private var selectedDay: DailyUsageStat?

    private var displayedStats: FullUsageStats {
        switch viewMode {
        case .week:
            let lastSevenDays = Array(stats.days.suffix(7))
            return FullUsageStats(days: lastSevenDays, dailyLimitMinutes: stats.dailyLimitMinutes)
        case .all:
            return stats
        }
    }

    private var isScrollable: Bool {
        viewMode == .all && stats.days.count > 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
                .padding(.horizontal)

            UsageChart(
                stats: displayedStats,
                scrollable: isScrollable,
                onDayTap: { day in
                    selectedDay = day
                }
            )
            .padding(.horizontal, isScrollable ? 0 : 16)

            summaryRow
                .padding(.horizontal)
        }
        .padding(.vertical)
        .glassCard()
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
        }
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)

            Text("Historie")
                .font(.headline)

            Spacer()

            if stats.days.count > 7 {
                Picker("", selection: $viewMode) {
                    ForEach(UsageViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            } else {
                Text("\(stats.days.count) dní")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summaryRow: some View {
        HStack {
            Label {
                Text("\(formatMinutes(displayedStats.averageMinutes)) průměr")
            } icon: {
                Image(systemName: "chart.bar.xaxis")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Text("Celkem: \(formatMinutes(displayedStats.totalMinutes))")
                .font(.caption)
                .foregroundStyle(.secondary)
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

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let day: DailyUsageStat

    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Celkový čas", systemImage: "clock.fill")
                        Spacer()
                        Text(formatMinutes(day.totalMinutes))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ContentUnavailableView {
                        Label("Detail aplikací", systemImage: "app.badge")
                    } description: {
                        Text("Detailní využití aplikací bude dostupné po připojení k Family Controls.")
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
#Preview("Short history (no toggle)") {
    UsageCard(stats: FullUsageStats.mock(days: 5))
        .padding()
}

#Preview("Week+ history (with toggle)") {
    UsageCard(stats: FullUsageStats.mock(days: 14))
        .padding()
}

#Preview("Long history") {
    UsageCard(stats: FullUsageStats.mock(days: 30))
        .padding()
}

#Preview("Day Detail") {
    DayDetailSheet(day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 127))
}
#endif
