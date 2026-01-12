import SwiftUI

struct PetScreenTimeCard: View {
    let pet: ActivePet
    var onTap: () -> Void
    var onDetailTap: () -> Void = {}

    @State private var selectedDay: DailyUsageStat?

    private var assetName: String {
        pet.essence.phase(at: pet.currentPhase)?.assetName(for: mood) ?? pet.essence.assetName
    }

    private var mood: Mood {
        Mood(from: pet.windLevel)
    }

    private var progress: Double {
        guard pet.dailyLimitMinutes > 0 else { return 0 }
        return min(Double(pet.todayUsedMinutes) / Double(pet.dailyLimitMinutes), 1.0)
    }

    private var progressPercent: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            if !pet.applicationTokens.isEmpty || !pet.categoryTokens.isEmpty {
                LimitedAppsPreview(
                    applicationTokens: pet.applicationTokens,
                    categoryTokens: pet.categoryTokens
                )
            }

            progressSection

            UsageChart(
                stats: pet.weeklyStats,
                themeColor: .green,
                onDayTap: { day in
                    selectedDay = day
                }
            )

            Text("Prumerne \(formatMinutes(pet.weeklyStats.averageMinutes)) denne")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .glassCard()
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.headline)

                if let purpose = pet.purpose {
                    Text(purpose)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onDetailTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(formatMinutes(pet.todayUsedMinutes))
                    .font(.system(size: 28, weight: .bold))

                Text("/ \(formatMinutes(pet.dailyLimitMinutes))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("dnes")
                    .foregroundStyle(.secondary)

                Text("vyuzito \(progressPercent)%")
                    .foregroundStyle(progressColor)
            }
            .font(.caption)
        }
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .green
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

#Preview("Under Limit") {
    PetScreenTimeCard(
        pet: .mock(todayUsedMinutes: 45, dailyLimitMinutes: 120),
        onTap: {}
    )
    .padding()
}

#Preview("Near Limit") {
    PetScreenTimeCard(
        pet: .mock(todayUsedMinutes: 100, dailyLimitMinutes: 120),
        onTap: {}
    )
    .padding()
}

#Preview("Over Limit") {
    PetScreenTimeCard(
        pet: .mock(todayUsedMinutes: 140, dailyLimitMinutes: 120),
        onTap: {}
    )
    .padding()
}
