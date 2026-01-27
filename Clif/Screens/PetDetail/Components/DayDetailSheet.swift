import FamilyControls
import SwiftUI

struct DayDetailSheet: View {
    let day: DailyUsageStat
    let sources: [LimitedSource]

    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "cs_CZ")
        f.dateStyle = .full
        return f
    }()

    private var sourcesForDay: [SourceUsage] {
        sources.compactMap { source -> SourceUsage? in
            guard let minutes = source.minutes(for: day.date) else { return nil }
            return SourceUsage(source: source, minutes: minutes)
        }
        .sorted { $0.minutes > $1.minutes }
    }

    private var maxMinutes: Int {
        sourcesForDay.map(\.minutes).max() ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalTimeCard

                    if !sourcesForDay.isEmpty {
                        appListCard
                    } else {
                        emptyState
                    }
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

    private var appListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(sourcesForDay.enumerated()), id: \.element.id) { index, usage in
                DayAppUsageRow(
                    source: usage.source,
                    minutes: usage.minutes,
                    maxMinutes: maxMinutes,
                    color: chartColor(for: index)
                )

                if index < sourcesForDay.count - 1 {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.vertical, 8)
        .glassCard()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Žádná data", systemImage: "app.badge")
        } description: {
            Text("Pro tento den nejsou k dispozici detailní data o aplikacích.")
        }
        .padding()
        .glassCard()
    }

    private func chartColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .cyan, .yellow, .mint]
        return colors[index % colors.count]
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

// MARK: - Source Usage

private struct SourceUsage: Identifiable {
    let id: UUID
    let source: LimitedSource
    let minutes: Int

    init(source: LimitedSource, minutes: Int) {
        self.id = source.id
        self.source = source
        self.minutes = minutes
    }
}

// MARK: - Day App Usage Row

private struct DayAppUsageRow: View {
    let source: LimitedSource
    let minutes: Int
    let maxMinutes: Int
    let color: Color

    private let iconSize: CGFloat = 36

    private var hasToken: Bool {
        switch source {
        case .app(let s): s.applicationToken != nil
        case .category(let s): s.categoryToken != nil
        case .website(let s): s.webDomainToken != nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                sourceIcon

                if hasToken {
                    sourceLabelWithName
                } else {
                    Text(source.displayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }

                Spacer()

                Text(formatMinutes(minutes))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            usageBar
                .padding(.leading, iconSize + 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var sourceLabelWithName: some View {
        switch source {
        case .app(let appSource):
            if let token = appSource.applicationToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }

        case .category(let catSource):
            if let token = catSource.categoryToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }

        case .website(let webSource):
            if let token = webSource.webDomainToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch source {
        case .app(let appSource):
            if let token = appSource.applicationToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                iconPlaceholder(systemName: "app.fill")
            }

        case .category(let catSource):
            if let token = catSource.categoryToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                iconPlaceholder(systemName: "square.grid.2x2.fill")
            }

        case .website(let webSource):
            if let token = webSource.webDomainToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                iconPlaceholder(systemName: "globe")
            }
        }
    }

    private func iconPlaceholder(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
            .frame(width: iconSize, height: iconSize)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var usageBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.quaternary)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: barWidth(in: geo.size.width), height: 4)
            }
        }
        .frame(height: 4)
    }

    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        guard maxMinutes > 0 else { return 0 }
        let fraction = CGFloat(minutes) / CGFloat(maxMinutes)
        return totalWidth * fraction
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
        sources: LimitedSource.mockList(days: 7)
    )
}

#Preview("Day Detail - Over Limit") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 185, wasOverLimit: true),
        sources: LimitedSource.mockList(days: 7)
    )
}

#Preview("Day Detail - Empty") {
    DayDetailSheet(
        day: DailyUsageStat(petId: UUID(), date: Date(), totalMinutes: 0),
        sources: []
    )
}
#endif
