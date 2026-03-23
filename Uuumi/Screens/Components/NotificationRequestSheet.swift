import SwiftUI

struct NotificationRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var permissionRequested = false
    @State private var permissionDenied = false
    @State private var permissionGranted = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(permissionGranted ? "You're all set!" : "Stay connected")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(permissionGranted
                     ? "Notifications are now enabled."
                     : "Get notified when your Uuumi is in danger or ready to evolve.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)

            Image(uiImage: UIImage(named: "notification-request") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)

            Spacer()

            VStack(spacing: 16) {
                if permissionGranted {
                    Button {
                        HapticType.impactLight.trigger()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .navigateToNotificationSettings, object: nil)
                        }
                    } label: {
                        Text("Customize notifications")
                    }
                    .buttonStyle(.primary)

                    Button {
                        HapticType.impactLight.trigger()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else if permissionDenied {
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

                    dismissButton
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
                            Text("Enable notifications")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(isRequesting)

                    dismissButton
                }
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await checkPermission() }
            }
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .denied {
                permissionDenied = true
            }
        }
    }

    private var dismissButton: some View {
        Button {
            HapticType.impactLight.trigger()
            dismiss()
        } label: {
            Text("Not now")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private func requestPermission() async {
        isRequesting = true
        await AppDelegate.requestNotificationPermission()
        permissionRequested = true
        await checkPermission()
        isRequesting = false
    }

    private func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let granted = settings.authorizationStatus == .authorized
        if granted {
            enableMasterToggle()
            withAnimation {
                permissionGranted = true
                permissionDenied = false
            }
        } else if settings.authorizationStatus == .denied {
            withAnimation {
                permissionDenied = true
            }
        }
    }

    private func enableMasterToggle() {
        var limitSettings = SharedDefaults.limitSettings
        guard !limitSettings.notifications.masterEnabled else { return }
        limitSettings.notifications.masterEnabled = true
        SharedDefaults.limitSettings = limitSettings
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NotificationRequestSheet()
        }
}
#endif
