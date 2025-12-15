import SwiftUI

struct StatusCardContentView: View {
    let streakCount: Int
    let usedTimeText: String
    let dailyLimitText: String
    let progress: Double

    var onSettingsTapped: () -> Void = { print("Settings tapped") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            timeRow

            ProgressBarView(progress: progress)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerRow: some View {
        HStack {
            streakBadge
            Spacer()
            settingsButton
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(.orange)
            Text("\(streakCount)")
        }
        .font(.system(size: 22, weight: .semibold))
    }

    private var settingsButton: some View {
        Button(action: onSettingsTapped) {
            Image(systemName: "gearshape")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var timeRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(usedTimeText)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)

            Text("/")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Text(dailyLimitText)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ZStack {
        Image("home")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()

        StatusCardContentView(
            streakCount: 19,
            usedTimeText: "32m",
            dailyLimitText: "2h",
            progress: 0.27
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(16)
    }
}
