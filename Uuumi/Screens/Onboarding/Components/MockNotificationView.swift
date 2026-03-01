import SwiftUI

/// A mock iOS notification banner for onboarding.
/// Pure UI component — does not send any real notifications.
struct MockNotificationView: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            appIcon

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("now")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(cornerRadius: 24)
    }

    private var appIcon: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if DEBUG
#Preview {
    ZStack {
        OnboardingBackgroundView()

        VStack(spacing: 12) {
            MockNotificationView(
                title: "I'm holding on!",
                message: "The wind is getting rough 💨"
            )

            MockNotificationView(
                title: "I'm ready to evolve!",
                message: "Come see what I become ✨"
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
