import SwiftUI

struct EvolutionTimelineView: View {
    let history: EvolutionHistory

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution Timeline")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(timelineItems.enumerated()), id: \.element.phase) { index, item in
                    timelineRow(item: item, isLast: index == timelineItems.count - 1)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        // Add all phases from 1 to maxPhase
        for phase in 1...history.maxPhase {
            let date = history.dateForPhase(phase)
            let isUnlocked = phase <= history.currentPhase
            let isCurrent = phase == history.currentPhase

            items.append(TimelineItem(
                phase: phase,
                date: date,
                isUnlocked: isUnlocked,
                isCurrent: isCurrent
            ))
        }

        return items
    }

    private func timelineRow(item: TimelineItem, isLast: Bool) -> some View {
        HStack(spacing: 16) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(item.isCurrent ? Color.green : (item.isUnlocked ? Color.primary : Color.secondary.opacity(0.3)))
                    .frame(width: 12, height: 12)
                    .overlay {
                        if item.isCurrent {
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 4)
                                .frame(width: 20, height: 20)
                        }
                    }

                if !isLast {
                    Rectangle()
                        .fill(item.isUnlocked ? Color.primary.opacity(0.3) : Color.secondary.opacity(0.15))
                        .frame(width: 2, height: 32)
                }
            }

            // Phase info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Phase \(item.phase)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.isUnlocked ? .primary : .secondary)

                    if item.isCurrent {
                        Text("Current")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green, in: Capsule())
                    }
                }

                if let date = item.date {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Locked")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

private struct TimelineItem {
    let phase: Int
    let date: Date?
    let isUnlocked: Bool
    let isCurrent: Bool
}

#if DEBUG
#Preview {
    VStack {
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

        EvolutionTimelineView(
            history: EvolutionHistory(
                createdAt: Date(),
                essence: .plant,
                events: []
            )
        )
    }
    .padding()
}
#endif
