import FamilyControls
import ManagedSettings
import SwiftUI

struct FallbackScreenTimeCard: View {
    let stats: WeeklyUsageStats
    let petId: UUID
    let limitMinutes: Int
    var applicationTokens: Set<ApplicationToken> = []
    var categoryTokens: Set<ActivityCategoryToken> = []

    @State private var selectedDay: DailyUsageStat?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            totalTimeSection

            if !applicationTokens.isEmpty || !categoryTokens.isEmpty {
                LimitedSourcesPreview(
                    applicationTokens: applicationTokens,
                    categoryTokens: categoryTokens
                )
            }

            UsageChart(
                stats: stats,
                themeColor: .green,
                onDayTap: { day in
                    selectedDay = day
                }
            )

            Text("Prumerne \(formatMinutes(stats.averageMinutes)) na den")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .glassCard()
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day, petId: petId, limitMinutes: limitMinutes, hourlyBreakdown: nil)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Cas u obrazovky")
            .font(.headline)
    }

    // MARK: - Total Time

    private var totalTimeSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(formatMinutes(stats.totalMinutes))
                .font(.system(size: 34, weight: .bold))
            Text("za poslednich 7 dni")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

#Preview {
    FallbackScreenTimeCard(stats: .mock(), petId: UUID(), limitMinutes: 60)
        .padding()
}
