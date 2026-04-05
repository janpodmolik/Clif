import SwiftUI

struct WelcomeBackNotificationPhase: View {
    let onDone: () -> Void

    @State private var permissionRequested = false
    @State private var permissionDenied = false
    @State private var isRequesting = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(AnalyticsManager.self) private var analytics

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                Text("Stay connected")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Uuumi can notify you when your pet is in danger or ready to evolve.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: 16) {
                if permissionDenied {
                    Text("You can enable notifications anytime in Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        HapticType.impactLight.trigger()
                        openSettings()
                    } label: {
                        Text("Open Settings")
                    }
                    .buttonStyle(.primary)

                    Button {
                        HapticType.impactLight.trigger()
                        onDone()
                    } label: {
                        Text("Skip")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color(.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground), in: Capsule())
                    }
                } else {
                    Button {
                        HapticType.impactLight.trigger()
                        Task { await requestPermission() }
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("Allow notifications")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(isRequesting)

                    Button {
                        HapticType.impactLight.trigger()
                        onDone()
                    } label: {
                        Text("Skip")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && permissionRequested {
                checkPermission()
            }
        }
    }

    private func requestPermission() async {
        isRequesting = true
        await AppDelegate.requestNotificationPermission()
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        analytics.send(.notificationPermissionResponded(granted: settings.authorizationStatus == .authorized))
        permissionRequested = true
        isRequesting = false
        checkPermission()
    }

    private func checkPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let granted = settings.authorizationStatus == .authorized
            withAnimation {
                permissionDenied = !granted
            }
            if granted { onDone() }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WelcomeBackNotificationPhase(onDone: {})
    }
}
#endif
