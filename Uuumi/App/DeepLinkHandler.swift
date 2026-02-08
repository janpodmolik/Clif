import SwiftUI

struct DeepLinkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                DeepLinkHandler.handle(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
                if let url = notification.object as? URL {
                    DeepLinkHandler.handle(url)
                }
            }
    }
}

extension View {
    func withDeepLinkHandling() -> some View {
        modifier(DeepLinkModifier())
    }
}

private enum DeepLinkHandler {
    static func handle(_ url: URL) {
        #if DEBUG
        print("[DeepLink] Received: \(url)")
        #endif

        guard url.scheme == "uuumi" else { return }

        switch url.host {
        case "shield":
            #if DEBUG
            print("[DeepLink] Opened from shield notification")
            #endif
            // TODO: Navigate to session tracking view when implemented

        case "pet":
            if let petIdString = url.pathComponents.dropFirst().first,
               let petId = UUID(uuidString: petIdString) {
                #if DEBUG
                print("[DeepLink] Navigate to pet: \(petId)")
                #endif
                NotificationCenter.default.post(
                    name: .selectPet,
                    object: nil,
                    userInfo: ["petId": petId]
                )
            }

        case "preset-picker":
            #if DEBUG
            print("[DeepLink] Opening preset picker from day start shield")
            #endif
            NotificationCenter.default.post(name: .showPresetPicker, object: nil)

        case "home":
            #if DEBUG
            print("[DeepLink] Navigate to home")
            #endif
            // Default behavior - just open app to home

        case "essenceCatalog":
            #if DEBUG
            print("[DeepLink] Navigate to essence catalog")
            #endif
            NotificationCenter.default.post(name: .showEssenceCatalog, object: nil)

        default:
            break
        }
    }
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let selectPet = Notification.Name("selectPet")
    static let showPresetPicker = Notification.Name("showPresetPicker")
    static let showEssenceCatalog = Notification.Name("showEssenceCatalog")
    #if DEBUG
    static let showMockSheet = Notification.Name("showMockSheet")
    #endif
}
