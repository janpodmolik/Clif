import Auth
import SwiftUI

struct PrivacySettingsScreen: View {
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(AuthManager.self) private var authManager
    @Environment(StoreManager.self) private var storeManager

    @State private var isOptedOut = PostHogOptOut.isOptedOut

    var body: some View {
        Form {
            Section {
                Toggle("Share Usage Analytics", isOn: Binding(
                    get: { !isOptedOut },
                    set: { newValue in
                        isOptedOut = !newValue
                        analytics.setAnalyticsOptedOut(!newValue)
                        if newValue {
                            Task {
                                await analytics.updateUser(
                                    userId: authManager.currentUser?.id,
                                    premiumPlan: storeManager.activeProductId
                                )
                            }
                        }
                    }
                ))
                .tint(.blue)
            } header: {
                Text("Analytics")
            } footer: {
                Text("Helps us understand how Uuumi is used so we can make it better. We never share your data with advertisers. You can turn this off any time.")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsScreen()
    }
    .environment(AnalyticsManager())
    .environment(AuthManager())
    .environment(StoreManager.mock())
}
