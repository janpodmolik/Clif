import Supabase
import SwiftUI

struct DayDetailSheet: View {
    let day: DailyUsageStat
    let petId: UUID
    let limitMinutes: Int
    let hourlyBreakdown: DailyHourlyBreakdown?

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var snapshots: [SnapshotEvent] = []
    @State private var restoredBreakdown: DailyHourlyBreakdown?
    @State private var showPremiumSheet = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let preset = selectedPreset {
                    presetCard(preset)
                }

                totalTimeCard

                if breakCount > 0 {
                    breakCard
            }

                windTimelineSection
                    .frame(maxHeight: storeManager.isPremium ? .infinity : nil)

                if !storeManager.isPremium {
                    Spacer()
                }
            }
            .padding()
            .navigationTitle(dateFormatter.string(from: day.date))
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .onAppear {
                loadSnapshots()
            }
        }
        .presentationDetents(storeManager.isPremium ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .premiumSheet(isPresented: $showPremiumSheet, source: .dayDetailTimeline)
    }

    private var breakCount: Int {
        snapshots.filter {
            if case .breakEnded = $0.eventType { return true }
            return false
        }.count
    }

    private var totalBreakMinutes: Int {
        snapshots.compactMap {
            if case .breakEnded(let minutes, _) = $0.eventType { return minutes }
            return nil
        }.reduce(0, +)
    }

    private var blowAwayReason: BlowAwayReason? {
        snapshots.first { $0.eventType.isBlowAway }?.eventType.blowAwayReason
    }

    private var selectedPreset: WindPreset? {
        day.preset
    }

    private var totalTimeCard: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Total time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatMinutes(day.totalMinutes))
                    .font(.title2.bold())
            }

            Spacer()

            if let reason = blowAwayReason {
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Blown Away", systemImage: reason.icon)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    Text(reason.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var breakCard: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(breakCount) \(breakCount == 1 ? "break" : "breaks")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatMinutes(totalBreakMinutes))
                    .font(.title2.bold())
            }

            Spacer()
        }
        .padding()
        .glassCard()
    }

    private func presetCard(_ preset: WindPreset) -> some View {
        HStack {
            Image(systemName: preset.iconName)
                .font(.title2)
                .foregroundStyle(preset.themeColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Preset")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(preset.displayName)
                    .font(.title2.bold())
            }

            Spacer()

            Text("\(Int(preset.minutesToBlowAway))m limit")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard()
    }

    @ViewBuilder
    private var windTimelineSection: some View {
        if storeManager.isPremium {
            if !snapshots.isEmpty {
                WindTimelineChart(snapshots: snapshots, limitMinutes: limitMinutes)
                    .padding()
                    .glassCard()
            } else if let breakdown = hourlyBreakdown ?? restoredBreakdown {
                DayHourlyChart(breakdown: breakdown)
                    .padding()
                    .glassCard()
            } else {
                emptyWindState
            }
        } else {
            timelineLockedCard
        }
    }

    private var timelineLockedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("See exactly when you used your phone.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PremiumButton("Unlock Timeline", style: .inline) { showPremiumSheet = true }
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassCard()
    }

    private var emptyWindState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Activity detail is not available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassCard()
    }

    private func loadSnapshots() {
        let dateString = SnapshotEvent.dateString(from: day.date)
        snapshots = SnapshotStore.shared.load(for: dateString, petId: petId)

        // Load fallback hourly breakdown from BE (if no snapshots and no breakdown passed in)
        if snapshots.isEmpty, hourlyBreakdown == nil {
            Task {
                restoredBreakdown = await Self.fetchBreakdownFromCloud(for: dateString, petId: petId)
            }
        }
    }

    /// Fetches a single day's hourly breakdown from BE for this pet.
    private static func fetchBreakdownFromCloud(for dateString: String, petId: UUID) async -> DailyHourlyBreakdown? {
        struct HourlyRow: Decodable {
            let hourlyPerDay: [DailyHourlyBreakdown]
            enum CodingKeys: String, CodingKey {
                case hourlyPerDay = "hourly_per_day"
            }
        }

        for table in ["active_pets", "archived_pets"] {
            guard let rows: [HourlyRow] = try? await SupabaseConfig.client
                .from(table)
                .select("hourly_per_day")
                .eq("id", value: petId.uuidString)
                .execute()
                .value,
                  let breakdowns = rows.first?.hourlyPerDay else { continue }

            if let match = breakdowns.first(where: { $0.date == dateString }) {
                return match
            }
        }
        return nil
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
#Preview("Day Detail") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 127),
        petId: UUID(),
        limitMinutes: 60,
        hourlyBreakdown: nil
    )
    .environment(StoreManager.mock())
}

#Preview("Day Detail - Over Limit") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 185, wasOverLimit: true),
        petId: UUID(),
        limitMinutes: 60,
        hourlyBreakdown: nil
    )
    .environment(StoreManager.mock())
}

#Preview("Day Detail - Hourly Fallback") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 127),
        petId: UUID(),
        limitMinutes: 60,
        hourlyBreakdown: DailyHourlyBreakdown(
            date: "2025-01-15",
            hourlyMinutes: [
                0, 0, 0, 0, 0, 0,
                2, 5, 15, 20, 8, 3,
                1, 5, 10, 12, 18, 25,
                30, 20, 10, 5, 2, 0
            ]
        )
    )
    .environment(StoreManager.mock())
}

#Preview("Day Detail - Empty") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 0),
        petId: UUID(),
        limitMinutes: 60,
        hourlyBreakdown: nil
    )
}

#endif
