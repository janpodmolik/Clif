import SwiftUI
import FamilyControls

struct OnboardingActivityView: View {
    let data: OnboardingReportData

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Daily average · last 7 days")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(data.formattedTotal.isEmpty ? "0m" : data.formattedTotal)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            if !data.apps.isEmpty {
                Divider()
                    .padding(.horizontal, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(data.apps.enumerated()), id: \.element.id) { index, app in
                            HStack(spacing: 14) {
                                if let token = app.token {
                                    Label(token)
                                        .labelStyle(.iconOnly)
                                        .scaleEffect(1.5)
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .foregroundStyle(.secondary)
                                }

                                if let name = app.name {
                                    Text(name)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(app.formattedDuration)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.001))

                            if index < data.apps.count - 1 {
                                Divider()
                                    .padding(.leading, 78)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    OnboardingActivityView(data: OnboardingReportData(
        formattedTotal: "4h 23m",
        apps: []
    ))
    .padding()
}
