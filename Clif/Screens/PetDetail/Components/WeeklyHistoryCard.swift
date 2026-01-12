import SwiftUI

struct WeeklyHistoryCard: View {
    let stats: BlockedAppsWeeklyStats
    var themeColor: Color = .green
    var dailyLimitMinutes: Int? = nil
    var onTap: (() -> Void)?

    @State private var selectedDay: BlockedAppsDailyStat?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            PetWeeklyChart(
                stats: stats,
                limitMinutes: dailyLimitMinutes,
                themeColor: themeColor,
                onDayTap: { day in
                    selectedDay = day
                }
            )

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

    private var summaryRow: some View {
        HStack {
            Label {
                Text("\(formatMinutes(stats.averageMinutes)) average")
            } icon: {
                Image(systemName: "chart.bar.xaxis")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Text("Total: \(formatMinutes(stats.totalMinutes))")
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
        PetActiveDetailScreenDebug()
    }
}

#Preview {
    VStack {
        WeeklyHistoryCard(stats: .mock(), themeColor: .green)

        WeeklyHistoryCard(stats: .mock(), themeColor: .blue, onTap: {})

        WeeklyHistoryCard(stats: .mock(), themeColor: .purple, onTap: {})
    }
    .padding()
}

#Preview("Day Detail") {
    DayDetailSheet(day: BlockedAppsDailyStat(date: Date(), totalMinutes: 127))
}
#endif
