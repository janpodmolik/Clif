import SwiftUI

enum UsageViewMode: String, CaseIterable {
    case week = "7 days"
    case all = "All"
}

struct DayByDayUsageCard: View {
    let stats: FullUsageStats
    let petId: UUID
    let limitMinutes: Int

    @Environment(StoreManager.self) private var storeManager
    @State private var viewMode: UsageViewMode = .week
    @State private var selectedDay: DailyUsageStat?
    @State private var showPremiumSheet = false

    private var displayedStats: FullUsageStats {
        switch viewMode {
        case .week:
            let lastSevenDays = Array(stats.days.suffix(7))
            return FullUsageStats(days: lastSevenDays)
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
                showDateLabel: true,
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
        .onAppear {
            if !storeManager.isPremium {
                viewMode = .week
            }
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet()
        }
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day, petId: petId, limitMinutes: limitMinutes, hourlyBreakdown: nil)
        }
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)

            Text("History")
                .font(.headline)

            Spacer()

            if stats.days.count > 7 {
                if storeManager.isPremium {
                    Picker("", selection: $viewMode) {
                        ForEach(UsageViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                } else {
                    Button {
                        showPremiumSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text("Premium")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(Color("PremiumGold"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("PremiumGold").opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("\(stats.days.count) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summaryRow: some View {
        HStack {
            Label {
                Text("\(formatMinutes(displayedStats.averageMinutes)) average")
            } icon: {
                Image(systemName: "chart.bar.xaxis")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Text("Total: \(formatMinutes(displayedStats.totalMinutes))")
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

#if DEBUG
#Preview("Short history (no toggle)") {
    DayByDayUsageCard(stats: FullUsageStats.mock(days: 5), petId: UUID(), limitMinutes: 60)
        .padding()
        .environment(StoreManager.mock())
}

#Preview("Week+ history (with toggle)") {
    DayByDayUsageCard(stats: FullUsageStats.mock(days: 14), petId: UUID(), limitMinutes: 60)
        .padding()
        .environment(StoreManager.mock())
}

#Preview("Long history") {
    DayByDayUsageCard(stats: FullUsageStats.mock(days: 30), petId: UUID(), limitMinutes: 60)
        .padding()
        .environment(StoreManager.mock())
}
#endif
