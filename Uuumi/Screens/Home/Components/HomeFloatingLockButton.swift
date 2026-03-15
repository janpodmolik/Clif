import SwiftUI

/// Floating lock/unlock button displayed over the home scene.
/// Manages its own break picker and unlock confirmation sheets.
struct HomeFloatingLockButton: View {
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(DefaultsKeys.lockButtonSide) private var lockButtonSide: LockButtonSide = .trailing
    @AppStorage(DefaultsKeys.lockButtonSize) private var lockButtonSize: LockButtonSize = .normal

    @State private var showBreakTypePicker = false
    @State private var showCommittedUnlock = false
    @State private var showSafetyUnlock = false
    @State private var isPulsingForUnlock = false

    private var shieldState: ShieldState { ShieldState.shared }

    let bottomPadding: CGFloat

    var body: some View {
        VStack {
            Spacer()
            HStack {
                if lockButtonSide == .trailing { Spacer() }
                floatingButton
                if lockButtonSide == .leading { Spacer() }
            }
            .padding(lockButtonSide == .trailing ? .trailing : .leading, 20)
            .padding(.bottom, bottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showBreakTypePicker) {
            BreakTypePicker(
                onSelectFree: {
                    analytics.sendBreakStarted(breakType: "free")
                    ShieldManager.shared.turnOn(breakType: .free, committedMode: nil)
                },
                onConfirmCommitted: { mode in
                    analytics.sendBreakStarted(breakType: "committed")
                    ShieldManager.shared.turnOn(breakType: .committed, committedMode: mode)
                }
            )
        }
        .unlockConfirmations(showCommitted: $showCommittedUnlock, showSafety: $showSafetyUnlock)
        .onReceive(NotificationCenter.default.publisher(for: .showBreakTypePicker)) { _ in
            showBreakTypePicker = true
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                checkPendingShieldUnlock()
            }
        }
        .onAppear {
            checkPendingShieldUnlock()
        }
    }

    // MARK: - Button

    @ViewBuilder
    private var floatingButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                buttonContent
                    .glassEffect(.regular.interactive(), in: .circle)
            } else {
                buttonContent
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .scaleEffect(isPulsingForUnlock ? 1.2 : 1.0)
        .animation(
            isPulsingForUnlock
                ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                : .default,
            value: isPulsingForUnlock
        )
        .overlay {
            if isPulsingForUnlock {
                pulseRing(delay: 0)
                pulseRing(delay: 0.6)
            }
        }
    }

    @ViewBuilder
    private func pulseRing(delay: Double) -> some View {
        Circle()
            .stroke(Color.accentColor.opacity(0.6), lineWidth: 2.5)
            .frame(width: lockButtonSize.frameSize, height: lockButtonSize.frameSize)
            .scaleEffect(isPulsingForUnlock ? 1.8 : 1.0)
            .opacity(isPulsingForUnlock ? 0 : 0.8)
            .animation(
                .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: isPulsingForUnlock
            )
    }

    private var buttonContent: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            stopPulsing()
            if shieldState.isActive {
                analytics.send(.shieldToggled(enabled: false))
                handleShieldUnlock(
                    shieldState: shieldState,
                    showCommittedConfirmation: $showCommittedUnlock,
                    showSafetyConfirmation: $showSafetyUnlock
                )
            } else {
                showBreakTypePicker = true
            }
        } label: {
            Image(systemName: shieldState.isActive ? "lock.fill" : "lock.open.fill")
                .font(lockButtonSize.iconFont)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: lockButtonSize.frameSize, height: lockButtonSize.frameSize)
        }
        .contentShape(Circle().inset(by: -10))
        .buttonStyle(.pressableButton)
    }

    // MARK: - Shield Unlock Pulse

    private func checkPendingShieldUnlock() {
        guard SharedDefaults.pendingShieldUnlock, shieldState.isActive else { return }
        SharedDefaults.pendingShieldUnlock = false
        isPulsingForUnlock = true

        Task {
            try? await Task.sleep(for: .seconds(3))
            stopPulsing()
        }
    }

    private func stopPulsing() {
        guard isPulsingForUnlock else { return }
        withAnimation(.default) {
            isPulsingForUnlock = false
        }
    }
}
