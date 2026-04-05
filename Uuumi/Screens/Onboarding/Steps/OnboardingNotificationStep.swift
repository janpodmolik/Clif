import SwiftUI

struct OnboardingNotificationStep: View {
    @Environment(AnalyticsManager.self) private var analytics

    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?
    @Binding var speechBubbleConfig: SpeechBubbleConfig?
    @Binding var speechBubbleVisible: Bool

    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // MARK: - Notification State

    @State private var showFirstNotification = false
    @State private var showSecondNotification = false
    @State private var notificationsCompleted = false

    // MARK: - Permission State

    @Environment(\.scenePhase) private var scenePhase

    @State private var showCTA = false
    @State private var permissionRequested = false
    @State private var permissionDenied = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()
                .frame(height: 24)

            notifications
                .padding(.horizontal, 16)

            Spacer()

            bottomArea
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .overlay {
            tapToSkipOverlay
        }
        .animation(.easeOut(duration: 0.3), value: showFirstNotification)
        .animation(.easeOut(duration: 0.3), value: showSecondNotification)
        .animation(.easeOut(duration: 0.3), value: showCTA)
        .animation(.easeOut(duration: 0.3), value: showButton)
        .animation(.easeOut(duration: 0.3), value: permissionDenied)
        .onAppear { handleAppear() }
        .onDisappear { handleDisappear() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && permissionRequested {
                checkIfPermissionGranted()
            }
        }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("You can't always be here.")
                Text("But Uuumi can reach you when it matters.")
                    .font(AppFont.quicksand(.callout, weight: .semiBold))
                    .foregroundStyle(.secondary)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "You can't always be here.",
                    skipRequested: skipped,
                    onCompleted: {
                        Task {
                            if !skipped {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showSecondLine = true }
                        }
                    }
                )

                TypewriterText(
                    text: "But Uuumi can reach you when it matters.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                        showNotifications()
                    }
                )
                .font(AppFont.quicksand(.callout, weight: .semiBold))
                .foregroundStyle(.secondary)
                .opacity(showSecondLine ? 1 : 0)
            }
        }
        .font(AppFont.quicksand(.title2, weight: .semiBold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Notifications

    private var notifications: some View {
        VStack(spacing: 10) {
            if showFirstNotification {
                MockNotificationView(
                    title: "I'm holding on!",
                    message: "The wind is getting rough"
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if showSecondNotification {
                MockNotificationView(
                    title: "I'm ready to evolve!",
                    message: "Come see what I become"
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if showButton {
            VStack(spacing: 16) {
                if permissionDenied {
                    Text("You can enable notifications in app settings anytime.")
                        .font(AppFont.quicksand(.footnote, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                    goToSettingsButton
                        .transition(.opacity)
                    skipButton
                        .transition(.opacity)
                } else {
                    continueButton
                        .transition(.opacity)
                }
            }
            .transition(.opacity)
        } else if showCTA {
            ctaButton
                .transition(.opacity)
        }
    }

    private var ctaButton: some View {
        Button {
            HapticType.impactLight.trigger()
            requestPermission()
        } label: {
            Text("Let Uuumi reach me")
        }
        .buttonStyle(.primary)
    }

    private var goToSettingsButton: some View {
        Button {
            HapticType.impactLight.trigger()
            openSettings()
        } label: {
            Text("Go to Settings")
        }
        .buttonStyle(.primary)
    }

    private var skipButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Skip")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground), in: Capsule())
        }
    }

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Tap to Skip

    @ViewBuilder
    private var tapToSkipOverlay: some View {
        if !skipAnimation && !permissionDenied {
            if !textCompleted {
                // Skip narrative
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticType.impactLight.trigger()
                        narrativeBeat += 1
                    }
            } else if !notificationsCompleted {
                // Skip notification animations
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticType.impactLight.trigger()
                        skipNotifications()
                    }
            }
        }
    }

    // MARK: - Actions

    private func showNotifications() {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !notificationsCompleted else { return }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showFirstNotification = true
            }

            // Show speech bubble on pet synchronized with first notification
            speechBubbleConfig = SpeechBubbleConfig(
                position: .right,
                emojis: ["🥺"],
                windLevel: .none,
                displayDuration: 4.0
            )
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                speechBubbleVisible = true
            }

            try? await Task.sleep(for: .seconds(1.2))
            guard !notificationsCompleted else { return }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSecondNotification = true
            }

            try? await Task.sleep(for: .seconds(0.6))
            guard !notificationsCompleted else { return }

            notificationsCompleted = true
            withAnimation { showCTA = true }
        }
    }

    private func skipNotifications() {
        notificationsCompleted = true
        withAnimation {
            showFirstNotification = true
            showSecondNotification = true
            showCTA = true
        }
        speechBubbleConfig = SpeechBubbleConfig(
            position: .right,
            emojis: ["🥺"],
            windLevel: .none,
            displayDuration: 3.0
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            speechBubbleVisible = true
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func checkIfPermissionGranted() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let granted = settings.authorizationStatus == .authorized
            withAnimation {
                permissionDenied = !granted
            }
        }
    }

    private func requestPermission() {
        Task {
            permissionRequested = true
            await AppDelegate.requestNotificationPermission()

            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let granted = settings.authorizationStatus == .authorized
            analytics.send(.notificationPermissionResponded(granted: granted))

            if granted {
                onContinue()
                return
            }

            withAnimation {
                showCTA = false
                permissionDenied = true
                showButton = true
            }
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        eyesOverride = "neutral"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showFirstNotification = true
            showSecondNotification = true

            if permissionRequested {
                showButton = true
            } else {
                showCTA = true
            }
        }
    }

    private func handleDisappear() {
        speechBubbleVisible = false
        speechBubbleConfig = nil
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride, _ in
        OnboardingNotificationStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride,
            speechBubbleConfig: .constant(nil),
            speechBubbleVisible: .constant(false)
        )
    }
}
#endif
