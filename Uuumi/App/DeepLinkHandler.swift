import SwiftUI

struct DeepLinkModifier: ViewModifier {
    @Environment(AuthManager.self) private var authManager
    @Environment(DeepLinkRouter.self) private var router

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handle(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
                if let url = notification.object as? URL {
                    handle(url)
                }
            }
    }

    private func handle(_ url: URL) {
        guard url.scheme == "uuumi" else { return }

        if url.host == DeepLinkHost.auth.rawValue {
            authManager.handleOAuthCallback(url: url)
        } else {
            #if DEBUG
            print("[DeepLink] Received: \(url)")
            #endif
            router.handle(url)
        }
    }
}

extension View {
    func withDeepLinkHandling() -> some View {
        modifier(DeepLinkModifier())
    }
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let selectPet = Notification.Name("selectPet")
    static let showEssenceCatalog = Notification.Name("showEssenceCatalog")
    static let navigateHome = Notification.Name("navigateHome")
    static let showBreakTypePicker = Notification.Name("showBreakTypePicker")
    #if DEBUG
    static let showMockSheet = Notification.Name("showMockSheet")
    #endif
}
