import DeviceActivity
import SwiftUI

struct OnboardingDataStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?

    @State private var showReport = false
    @State private var showContinue = false

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)
                .padding(.bottom, 16)

            if showReport {
                screenTimeReportView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 12)

            if showContinue {
                continueButton
                    .transition(.opacity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
            .onAppear {
                eyesOverride = "neutral"

                if skipAnimation {
                    showReport = true
                    showContinue = true
                } else {
                    Task {
                        try? await Task.sleep(for: .seconds(0.6))
                        withAnimation(.easeOut(duration: 0.5)) {
                            showReport = true
                        }
                        try? await Task.sleep(for: .seconds(0.8))
                        withAnimation(.easeOut(duration: 0.3)) {
                            showContinue = true
                        }
                    }
                }
            }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 8) {
            Text("This is what Uuumi is up against.")
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .foregroundStyle(.primary)

            Text("Your screen time speaks for itself.")
                .font(AppFont.quicksand(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Screen Time Report

    private var screenTimeReportView: some View {
        DeviceActivityReport(.onboardingOverview, filter: onboardingReportFilter)
            .frame(minHeight: 200)
            .glassBackground(cornerRadius: 20)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var onboardingReportFilter: DeviceActivityFilter {
        let now = Date.now
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: now))!
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!
        let interval = DateInterval(start: weekAgo, end: endOfToday)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(windProgress: 0.15, showWind: true) { _, _, eyesOverride in
        OnboardingDataStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride
        )
    }
}
#endif
