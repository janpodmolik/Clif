import SwiftUI
import FamilyControls

struct ArchivedPetDetailScreen: View {
    let pet: ArchivedPet

    @Environment(\.dismiss) private var dismiss
    @State private var showAppUsageSheet = false
    @State private var showBreakHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ArchivedPetHeaderCard(
                        petName: pet.name,
                        totalDays: pet.totalDays,
                        evolutionPhase: pet.finalPhase,
                        createdAt: pet.evolutionHistory.createdAt,
                        isBlown: pet.isBlown,
                        archivedAt: pet.archivedAt,
                        purpose: pet.purpose
                    )

                    EssenceInfoCard(evolutionHistory: pet.evolutionHistory)

                    EvolutionCarousel(
                        pet: pet,
                        windLevel: .none,
                        isBlownAway: pet.isBlown,
                        showCurrentBadge: false
                    )

                    EvolutionTimelineView(
                        history: pet.evolutionHistory,
                        canEvolve: false,
                        daysUntilEvolution: nil,
                        showPulse: false
                    )

                    DayByDayUsageCard(stats: pet.fullStats)

                    TrendMiniChart(stats: pet.fullStats)

                    if !pet.breakHistory.isEmpty {
                        BreakSummaryButton(
                            breakHistory: pet.breakHistory,
                            onTap: { showBreakHistory = true }
                        )
                    }

                    LimitedAppsButton(
                        sources: pet.limitedSources,
                        onTap: { showAppUsageSheet = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showBreakHistory) {
                BreakHistorySheet(breakHistory: pet.breakHistory)
            }
            .sheet(isPresented: $showAppUsageSheet) {
                AppUsageDetailSheet(
                    sources: pet.limitedSources,
                    preset: pet.preset,
                    totalDays: pet.totalDays
                )
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - App Usage Detail Sheet

struct AppUsageDetailSheet: View {
    let sources: [LimitedSource]
    let preset: WindPreset
    let totalDays: Int

    @Environment(\.dismiss) private var dismiss

    private var sortedSources: [LimitedSource] {
        sources.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    private var totalMinutes: Int {
        sources.reduce(0) { $0 + $1.totalMinutes }
    }

    private var maxMinutes: Int {
        sources.map(\.totalMinutes).max() ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if sources.count > 1 {
                        UsageDonutChart(
                            sources: sortedSources,
                            totalMinutes: totalMinutes
                        )
                        .padding()
                        .glassCard()
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(sortedSources.enumerated()), id: \.element.id) { index, source in
                            AppUsageRow(
                                source: source,
                                maxMinutes: maxMinutes,
                                color: chartColor(for: index)
                            )

                            if index < sortedSources.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .glassCard()
                }
                .padding()
            }
            .navigationTitle("Používání")
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

    private func chartColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .cyan, .yellow, .mint]
        return colors[index % colors.count]
    }
}

// MARK: - Donut Chart

private struct UsageDonutChart: View {
    let sources: [LimitedSource]
    let totalMinutes: Int

    private let chartSize: CGFloat = 160
    private let lineWidth: CGFloat = 24

    var body: some View {
        ZStack {
            donutSegments

            VStack(spacing: 2) {
                Text(formatMinutes(totalMinutes))
                    .font(.title2.bold())
                Text("celkem")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: chartSize, height: chartSize)
    }

    private var donutSegments: some View {
        let total = Double(max(totalMinutes, 1))
        var startAngle = -90.0

        return ZStack {
            ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                let fraction = Double(source.totalMinutes) / total
                let endAngle = startAngle + (fraction * 360)

                DonutSegment(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    lineWidth: lineWidth
                )
                .fill(chartColor(for: index))

                let _ = { startAngle = endAngle }()
            }
        }
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

private struct DonutSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
    }
}

// MARK: - App Usage Row

private struct AppUsageRow: View {
    let source: LimitedSource
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

                Text(formatMinutes(source.totalMinutes))
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
        let fraction = CGFloat(source.totalMinutes) / CGFloat(maxMinutes)
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

#Preview("Blown") {
    ArchivedPetDetailScreen(pet: .mock(name: "Storm", phase: 3, isBlown: true))
}

#Preview("Fully Evolved") {
    ArchivedPetDetailScreen(pet: .mock(name: "Breeze", phase: 4, isBlown: false, totalDays: 14))
}

#Preview("App Usage Sheet") {
    AppUsageDetailSheet(
        sources: LimitedSource.mockList(days: 14),
        preset: .balanced,
        totalDays: 14
    )
}
