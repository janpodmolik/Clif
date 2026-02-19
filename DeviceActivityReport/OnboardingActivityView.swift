import SwiftUI
import FamilyControls

struct OnboardingActivityView: View {
    let data: OnboardingReportData

    var body: some View {
        VStack(spacing: 16) {
            // Total screen time
            VStack(spacing: 4) {
                Text("Today")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(data.formattedTotal.isEmpty ? "0m" : data.formattedTotal)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }

            // Top apps
            if !data.apps.isEmpty {
                VStack(spacing: 6) {
                    ForEach(data.apps) { app in
                        HStack(spacing: 10) {
                            if let token = app.token {
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))

                                Label(token)
                                    .labelStyle(.titleOnly)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "app.fill")
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(app.formattedDuration)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    OnboardingActivityView(data: OnboardingReportData(
        formattedTotal: "4h 23m",
        apps: []
    ))
    .padding()
}
