import SwiftUI

struct DayDetailSheet: View {
    let day: DailyUsageStat
    let petId: UUID
    let limitMinutes: Int

    @Environment(\.dismiss) private var dismiss
    @State private var snapshots: [SnapshotEvent] = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalTimeCard

                    if breakCount > 0 {
                        breakCard
                    }

                    windTimelineSection
                }
                .padding()
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
            .onAppear {
                loadSnapshots()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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

    private var totalTimeCard: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Celkový čas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatMinutes(day.totalMinutes))
                    .font(.title2.bold())
            }

            Spacer()

            if let reason = blowAwayReason {
                VStack(alignment: .trailing, spacing: 2) {
                    Label("Odfouknut", systemImage: reason.icon)
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
                Text("\(breakCount) \(breakCount == 1 ? "pauza" : breakCount < 5 ? "pauzy" : "pauz")")
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

    private var windTimelineSection: some View {
        WindTimelineChart(snapshots: snapshots, limitMinutes: limitMinutes)
            .padding()
            .glassCard()
    }

    private func loadSnapshots() {
        let dateString = SnapshotEvent.dateString(from: day.date)
        snapshots = SnapshotStore.shared.load(for: dateString, petId: petId)
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
        limitMinutes: 60
    )
}

#Preview("Day Detail - Over Limit") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 185, wasOverLimit: true),
        petId: UUID(),
        limitMinutes: 60
    )
}

#Preview("Day Detail - Empty") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 0),
        petId: UUID(),
        limitMinutes: 60
    )
}

#endif
