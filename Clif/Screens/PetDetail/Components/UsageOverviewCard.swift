import SwiftUI

struct UsageOverviewCard: View {
    let stats: FullUsageStats
    let breakCount: Int
    let totalBreakMinutes: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Přehled")
                .font(.headline)

            // Total time + average per day
            HStack(spacing: 12) {
                statItem(
                    value: formatMinutes(stats.totalMinutes),
                    label: "Celkový čas",
                    icon: "clock.fill",
                    color: .blue
                )

                statItem(
                    value: formatMinutes(stats.averageMinutes),
                    label: "Průměr/den",
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }

            // Breaks
            if breakCount > 0 {
                HStack(spacing: 12) {
                    statItem(
                        value: "\(breakCount)",
                        label: "Pauz",
                        icon: "pause.circle.fill",
                        color: .green
                    )

                    statItem(
                        value: formatMinutes(Int(totalBreakMinutes)),
                        label: "V pauzách",
                        icon: "timer",
                        color: .teal
                    )
                }
            }

            // Preset distribution
            let distribution = stats.presetDistribution
            if !distribution.isEmpty {
                presetDistributionSection(distribution)
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Stat Item

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold))

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Preset Distribution

    private func presetDistributionSection(_ distribution: [WindPreset: Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Režimy")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            presetBar(distribution)

            HStack(spacing: 12) {
                ForEach(sortedPresets(distribution), id: \.0) { preset, count in
                    presetLegendItem(preset: preset, count: count)
                }
            }
        }
    }

    private func presetBar(_ distribution: [WindPreset: Int]) -> some View {
        let total = distribution.values.reduce(0, +)
        let sorted = sortedPresets(distribution)

        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(sorted, id: \.0) { preset, count in
                    let fraction = CGFloat(count) / CGFloat(max(total, 1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(preset.themeColor)
                        .frame(width: max((geo.size.width - CGFloat(sorted.count - 1) * 2) * fraction, 4))
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    private func presetLegendItem(preset: WindPreset, count: Int) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(preset.themeColor)
                .frame(width: 8, height: 8)

            Text("\(preset.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(count)d")
                .font(.caption.weight(.medium))
        }
    }

    private func sortedPresets(_ distribution: [WindPreset: Int]) -> [(WindPreset, Int)] {
        distribution.sorted { $0.value > $1.value }
    }

    // MARK: - Helpers

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
#Preview("Full") {
    UsageOverviewCard(
        stats: .mock(days: 14),
        breakCount: 8,
        totalBreakMinutes: 120
    )
    .padding()
}

#Preview("No Breaks") {
    UsageOverviewCard(
        stats: .mock(days: 7),
        breakCount: 0,
        totalBreakMinutes: 0
    )
    .padding()
}

#Preview("Single Preset") {
    let petId = UUID()
    let days = (0..<5).map { i in
        DailyUsageStat(
            petId: petId,
            date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
            totalMinutes: Int.random(in: 30...90),
            preset: .balanced
        )
    }
    UsageOverviewCard(
        stats: FullUsageStats(days: days),
        breakCount: 3,
        totalBreakMinutes: 45
    )
    .padding()
}
#endif
