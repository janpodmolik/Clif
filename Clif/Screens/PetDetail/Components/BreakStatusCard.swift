import SwiftUI

struct BreakStatusCard: View {
    let activeBreak: ActiveBreak
    let currentWindPoints: Double
    var onEndBreak: () -> Void

    @State private var isPulsing = false

    private var breakType: BreakType {
        activeBreak.type
    }

    /// Wind after break completes (for committed/hardcore)
    private var predictedWindAfter: Double {
        max(currentWindPoints - activeBreak.windDecreased, 0)
    }

    /// Estimated minutes until wind reaches 0 (for free break)
    private var minutesToZeroWind: Int? {
        guard breakType == .free else { return nil }
        guard activeBreak.decreaseRate > 0 else { return nil }
        let remainingWind = currentWindPoints - activeBreak.windDecreased
        guard remainingWind > 0 else { return 0 }
        return Int(ceil(remainingWind / activeBreak.decreaseRate))
    }

    var body: some View {
        VStack(spacing: 16) {
            headerRow

            if let progress = activeBreak.progress {
                ProgressBarView(progress: progress, isPulsing: true)
            }

            infoRow
            endBreakButton
        }
        .padding()
        .glassCard()
        .onAppear { isPulsing = true }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)

                Text("Calming the Wind")
                    .font(.headline)
            }

            Spacer()

            breakTypeBadge
        }
    }

    private var breakTypeBadge: some View {
        Text(breakType.displayName)
            .font(.caption.weight(.medium))
            .foregroundStyle(breakTypeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(breakTypeColor.opacity(0.15), in: Capsule())
    }

    private var breakTypeColor: Color {
        switch breakType {
        case .free: return .green
        case .committed: return .orange
        case .hardcore: return .red
        }
    }

    // MARK: - Info Row

    private var infoRow: some View {
        HStack {
            // Left side: countdown or elapsed time
            VStack(alignment: .leading, spacing: 2) {
                if let remaining = activeBreak.remainingSeconds {
                    Text(formatTime(remaining))
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(formatTime(activeBreak.elapsedMinutes * 60))
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("elapsed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(isPulsing ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

            Spacer()

            // Right side: wind prediction
            VStack(alignment: .trailing, spacing: 2) {
                if breakType == .free {
                    if let minutes = minutesToZeroWind {
                        Text("\(formatDuration(minutes))")
                            .font(.system(.title3, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.green)
                        Text("to wind 0%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("\(Int(predictedWindAfter))%")
                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.green)
                    Text("wind after")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - End Break Button

    private var endBreakButton: some View {
        Button(action: onEndBreak) {
            HStack(spacing: 8) {
                Image(systemName: "wind")
                Text("Release the Wind")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.cyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.cyan.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}

#if DEBUG
#Preview("Committed Break") {
    BreakStatusCard(
        activeBreak: .mock(type: .committed, minutesAgo: 10, durationMinutes: 30),
        currentWindPoints: 65,
        onEndBreak: {}
    )
    .padding()
}

#Preview("Hardcore Break") {
    BreakStatusCard(
        activeBreak: .mock(type: .hardcore, minutesAgo: 5, durationMinutes: 15),
        currentWindPoints: 80,
        onEndBreak: {}
    )
    .padding()
}

#Preview("Free Break - Unlimited") {
    BreakStatusCard(
        activeBreak: .unlimitedFree(),
        currentWindPoints: 45,
        onEndBreak: {}
    )
    .padding()
}
#endif
