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

            if day.wasOverLimit {
                Label("Překročen limit", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
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
