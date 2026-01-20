import SwiftUI

/// Compact button to access break history for DynamicPet.
struct BreakSummaryCard: View {
    let breakHistory: [CompletedBreak]
    var onTap: (() -> Void)?

    // MARK: - Computed

    private var totalBreaks: Int {
        breakHistory.count
    }

    private var totalMinutes: Double {
        breakHistory.reduce(0) { $0 + $1.durationMinutes }
    }


    // MARK: - Body

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                    .background(.cyan.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Breaks")
                        .font(.subheadline.weight(.medium))

                    Text("\(totalBreaks) breaks · \(formatMinutes(totalMinutes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(totalMinutes)m"
    }
}

// MARK: - BreakType Color Extension

private extension BreakType {
    var color: Color {
        switch self {
        case .free: return .green
        case .committed: return .orange
        case .hardcore: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Breaks") {
    BreakSummaryCard(
        breakHistory: CompletedBreak.mockList(),
        onTap: {}
    )
    .padding()
}

#Preview("No Tap Action") {
    BreakSummaryCard(
        breakHistory: CompletedBreak.mockList()
    )
    .padding()
}
#endif
