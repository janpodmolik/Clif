import SwiftUI

enum DeepLinkHost: String {
    case auth
    case dailySummary
    case presetPicker = "preset-picker"
    case pet
    case home
    case essenceCatalog
    case shield
}

@Observable
final class DeepLinkRouter {

    /// Action waiting for a blocking sheet (preset picker) to dismiss.
    private(set) var pendingAction: DeepLinkAction?

    // MARK: - Observable Triggers

    /// Set when a daily summary deep link is received. Consumed by HomeScreen via `.sheet(item:)`.
    var showDailySummary: DailySummaryRequest?

    /// Preset picker state — owned here so the router can queue actions behind it.
    var showPresetPicker = false

    // MARK: - Handle

    func handle(_ url: URL) {
        guard url.scheme == "uuumi",
              let host = url.host.flatMap(DeepLinkHost.init) else { return }

        switch host {
        case .auth:
            // Handled by DeepLinkModifier before reaching the router
            break

        case .dailySummary:
            #if DEBUG
            print("[DeepLink] Navigate to daily summary")
            #endif
            // Switch to home tab
            NotificationCenter.default.post(name: .navigateHome, object: nil)

            let request = DailySummaryRequest(notificationDate: parseDate(from: url))
            if showPresetPicker {
                pendingAction = .dailySummary(request)
            } else {
                showDailySummary = request
            }

        case .presetPicker:
            #if DEBUG
            print("[DeepLink] Opening preset picker from day start shield")
            #endif
            NotificationCenter.default.post(name: .navigateHome, object: nil)
            showPresetPicker = true

        case .pet:
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

        case .home:
            #if DEBUG
            print("[DeepLink] Navigate to home")
            #endif
            NotificationCenter.default.post(name: .navigateHome, object: nil)

        case .essenceCatalog:
            #if DEBUG
            print("[DeepLink] Navigate to essence catalog")
            #endif
            NotificationCenter.default.post(name: .showEssenceCatalog, object: nil)

        case .shield:
            #if DEBUG
            print("[DeepLink] Opened from shield notification")
            #endif

        }
    }

    /// Call from preset picker's `onDismiss` to execute any queued action.
    func drainPendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        switch action {
        case .dailySummary(let request):
            showDailySummary = request
        }
    }

    // MARK: - Private

    private func parseDate(from url: URL) -> Date? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let str = components.queryItems?.first(where: { $0.name == "date" })?.value,
              let ts = Double(str) else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
}

// MARK: - Supporting Types

struct DailySummaryRequest: Identifiable, Equatable {
    let id = UUID()
    let notificationDate: Date?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

enum DeepLinkAction {
    case dailySummary(DailySummaryRequest)
}
