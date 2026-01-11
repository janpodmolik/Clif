import SwiftUI

struct EvolutionTimelineView: View {
    let history: EvolutionHistory
    var blownAt: Date? = nil
    var canEvolve: Bool = false
    var daysUntilEvolution: Int? = nil
    var themeColor: Color = .green

    @State private var isPulsing = false

    private var isBlown: Bool { blownAt != nil }

    private let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution Timeline")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(1...history.maxPhase, id: \.self) { phase in
                        HStack(spacing: 0) {
                            milestoneItem(phase: phase)

                            if phase < history.maxPhase {
                                connectorLine(isUnlocked: phase < history.currentPhase)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .scrollClipDisabled()

            if let blownAt {
                blownAwayLabel(date: blownAt)
            } else {
                evolutionStatusLabel
            }
        }
        .padding()
        .glassCard()
    }

    @ViewBuilder
    private var evolutionStatusLabel: some View {
        if canEvolve {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Ready to evolve!")
                    .fontWeight(.medium)
            }
            .font(.caption)
            .foregroundStyle(themeColor)
        } else if history.currentPhase >= history.maxPhase {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(themeColor)
                Text("Fully evolved")
                    .fontWeight(.medium)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let days = daysUntilEvolution {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text(days == 1 ? "Next evolution tomorrow" : "Next evolution in \(days) days")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func blownAwayLabel(date: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "wind")
            Text("Blown away")
                .fontWeight(.medium)
            Text(shortDateFormatter.string(from: date))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.red)
    }

    private func milestoneItem(phase: Int) -> some View {
        let isUnlocked = phase <= history.currentPhase
        let isCurrent = phase == history.currentPhase
        let date = history.dateForPhase(phase)

        return VStack(spacing: 4) {
            // Circle with phase number
            ZStack {
                Circle()
                    .fill(circleColor(isUnlocked: isUnlocked, isCurrent: isCurrent))
                    .frame(width: 32, height: 32)

                if isCurrent {
                    let pulseColor: Color = isBlown ? .red : themeColor
                    Circle()
                        .stroke(pulseColor.opacity(isPulsing ? 0.0 : 0.5), lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                        .onAppear { isPulsing = true }
                }

                Text("\(phase)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isUnlocked ? .white : .secondary)
            }

            // Date label
            if let date = date {
                Text(shortDateFormatter.string(from: date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(minWidth: 50)
    }

    private func connectorLine(isUnlocked: Bool) -> some View {
        Rectangle()
            .fill(isUnlocked ? Color.primary.opacity(0.3) : Color.secondary.opacity(0.15))
            .frame(width: 20, height: 2)
            .padding(.bottom, 20) // Offset to align with circles, not dates
    }

    private func circleColor(isUnlocked: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return isBlown ? .red : themeColor
        } else if isUnlocked {
            return .primary.opacity(0.6)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        // 2 phases reached
        EvolutionTimelineView(
            history: EvolutionHistory(
                createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                essence: .plant,
                events: [
                    EvolutionEvent(
                        fromPhase: 1,
                        toPhase: 2,
                        date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                    )
                ]
            )
        )

        // New pet - phase 1 only
        EvolutionTimelineView(
            history: EvolutionHistory(
                createdAt: Date(),
                essence: .plant,
                events: []
            )
        )

        // Max evolution
        EvolutionTimelineView(
            history: EvolutionHistory(
                createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                essence: .plant,
                events: [
                    EvolutionEvent(fromPhase: 1, toPhase: 2, date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!),
                    EvolutionEvent(fromPhase: 2, toPhase: 3, date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!),
                    EvolutionEvent(fromPhase: 3, toPhase: 4, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
                ]
            )
        )
    }
    .padding()
}
#endif
