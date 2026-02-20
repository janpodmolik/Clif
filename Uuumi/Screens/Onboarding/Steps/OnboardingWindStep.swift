import DeviceActivity
import SwiftUI

struct OnboardingWindStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showPermissionCTA = false
    @State private var showPermissionDenied = false
    @State private var isRequestingPermission = false

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                narrative
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
            }
            .overlay(alignment: .bottom) {
                bottomArea
                    .padding(.horizontal, 24)
            }
            .onAppear {
                if skipAnimation {
                    windProgress = 0.15
                    eyesOverride = "neutral"
                    textCompleted = true
                    showSecondLine = true
                    showThirdLine = true
                    showPermissionCTA = true
                }
            }
            .onDisappear {
                eyesOverride = nil
            }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("The wind comes from your screen time.")
                Text("The more you scroll, the stronger it gets.")
                Text("Let's see what Uuumi is up against.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                TypewriterText(
                    text: "The wind comes from your screen time.",
                    onCompleted: {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            windProgress = 0.08
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation { showSecondLine = true }
                        }
                    }
                )

                TypewriterText(
                    text: "The more you scroll, the stronger it gets.",
                    active: showSecondLine,
                    onCompleted: {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            windProgress = 0.15
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(0.8))
                            // Show third line with neutral eyes
                            eyesOverride = "neutral"
                            withAnimation(.easeIn(duration: 0.6)) {
                                showThirdLine = true
                            }
                            textCompleted = true
                            withAnimation(.easeOut(duration: 0.4)) {
                                showPermissionCTA = true
                            }
                        }
                    }
                )
                .opacity(showSecondLine ? 1 : 0)

                Text("Let's see what Uuumi is up against.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
                    .opacity(showThirdLine ? 1 : 0)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if screenTimeManager.isAuthorized {
            VStack(spacing: 16) {
                screenTimeReportView
                continueButton
            }
            .transition(.opacity)
        } else if showPermissionCTA {
            permissionCTAView
                .transition(.opacity)
        }
    }

    // MARK: - Permission CTA

    private var permissionCTAView: some View {
        VStack(spacing: 16) {
            if showPermissionDenied {
                Text("Uuumi needs Screen Time access to work. Without it, there's no wind, no protection, no evolution.")
                    .font(AppFont.quicksand(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Text("Your data stays on your device. Always.")
                .font(AppFont.quicksand(.caption, weight: .medium))
                .foregroundStyle(.secondary)

            Button {
                HapticType.impactMedium.trigger()
                requestPermission()
            } label: {
                if isRequestingPermission {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(showPermissionDenied ? "Try again" : "Show my screen time")
                }
            }
            .buttonStyle(.primary)
            .disabled(isRequestingPermission)
        }
    }

    // MARK: - Screen Time Report

    private var screenTimeReportView: some View {
        DeviceActivityReport(.onboardingOverview, filter: onboardingReportFilter)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var onboardingReportFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: .now)
            ?? DateInterval(start: .now, duration: 86400)
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

    // MARK: - Actions

    private func requestPermission() {
        isRequestingPermission = true
        showPermissionDenied = false
        Task {
            await screenTimeManager.requestAuthorization()
            isRequestingPermission = false
            if !screenTimeManager.isAuthorized {
                withAnimation {
                    showPermissionDenied = true
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            DayBackgroundView()
            WindLinesView(
                windProgress: 0.15,
                direction: 1.0,
                windAreaTop: 0.08,
                windAreaBottom: 0.42
            )
            .allowsHitTesting(false)
            OnboardingIslandView(
                screenHeight: geometry.size.height,
                pet: Blob.shared,
                windProgress: 0.15
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
            OnboardingWindStep(
                skipAnimation: false,
                onContinue: {},
                windProgress: .constant(0.15),
                eyesOverride: .constant(nil)
            )
        }
    }
}
#endif
