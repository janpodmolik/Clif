import SwiftUI

/// Floating lock/unlock button displayed over the home scene.
/// Manages its own break picker and unlock confirmation sheets.
struct HomeFloatingLockButton: View {
    @Environment(AnalyticsManager.self) private var analytics
    @AppStorage(DefaultsKeys.lockButtonSide) private var lockButtonSide: LockButtonSide = .trailing

    @State private var showBreakTypePicker = false
    @State private var showCommittedUnlock = false
    @State private var showSafetyUnlock = false

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
                    ShieldManager.shared.turnOn(breakType: .free, durationMinutes: nil)
                },
                onConfirmCommitted: { durationMinutes in
                    analytics.sendBreakStarted(breakType: "committed")
                    ShieldManager.shared.turnOn(breakType: .committed, durationMinutes: durationMinutes)
                }
            )
        }
        .unlockConfirmations(showCommitted: $showCommittedUnlock, showSafety: $showSafetyUnlock)
        .onReceive(NotificationCenter.default.publisher(for: .showBreakTypePicker)) { _ in
            showBreakTypePicker = true
        }
    }

    // MARK: - Button

    @ViewBuilder
    private var floatingButton: some View {
        if #available(iOS 26.0, *) {
            buttonContent
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            buttonContent
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var buttonContent: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                .font(.title2.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 55, height: 55)
        }
        .contentShape(Circle().inset(by: -10))
        .buttonStyle(.pressableButton)
    }
}
