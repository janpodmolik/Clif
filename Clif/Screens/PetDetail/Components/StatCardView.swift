import SwiftUI

struct StatCardView<S: StatType>: View {
    let stat: S
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 16) {
                iconView

                contentView

                Spacer()

                if let progress = stat.progress {
                    CircularProgressView(progress: progress, color: stat.tintColor)
                        .frame(width: 44, height: 44)
                }

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    private var iconView: some View {
        Image(systemName: stat.iconName)
            .font(.system(size: 24))
            .foregroundStyle(stat.tintColor)
            .frame(width: 44, height: 44)
            .background(stat.tintColor.opacity(0.15), in: Circle())
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(stat.primaryValue)
                    .font(.title2.weight(.bold))

                if let secondary = stat.secondaryValue {
                    Text(secondary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(progress > 1.0 ? .red : .primary)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        StatCardView(stat: ScreenTimeStat(usedMinutes: 45, limitMinutes: 120))

        StatCardView(stat: ScreenTimeStat(usedMinutes: 90, limitMinutes: 120))

        StatCardView(
            stat: ScreenTimeStat(usedMinutes: 150, limitMinutes: 120),
            onTap: {}
        )

        StatCardView(stat: StepsStat(steps: 7500, goal: 10000))
    }
    .padding()
}
#endif
