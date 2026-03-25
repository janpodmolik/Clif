import Foundation
import Observation
import Statsig

@Observable
final class AnalyticsManager {

    private var isStarted = false
    private var pendingEvents: [(Event)] = []

    // MARK: - Event Definitions

    enum Event {
        // Lifecycle
        case appOpened
        case onboardingCompleted

        // Pet
        case petCreated(source: String)
        case presetSelected(preset: String, context: PresetContext)
        case limitedAppsChanged(appCount: Int)
        case essenceApplied(essence: String)
        case petEvolved(essence: String, phase: Int)
        case petArchived(essence: String, phase: Int, days: Int, reason: String)

        // Breaks
        case breakStarted(type: String, duration: Int?)
        case breakEnded(type: String, durationMinutes: Int, success: Bool)
        case blowAway(essence: String, phase: Int, days: Int)

        // Auth
        case authCompleted(method: String)

        // Purchase
        case paywallShown(source: String, type: String)
        case purchaseCompleted(product: String, source: String, revenue: String)
        case purchaseFailed(product: String, source: String, reason: String)

        // Config
        case configChanged(key: String, value: String)

        // Permissions
        case notificationPermissionResponded(granted: Bool)

        enum PresetContext: String {
            case onboarding
            case creation
            case daily
        }

        var name: String {
            switch self {
            case .appOpened: "app_opened"
            case .onboardingCompleted: "onboarding_completed"
            case .petCreated: "pet_created"
            case .presetSelected: "preset_selected"
            case .limitedAppsChanged: "limited_apps_changed"
            case .essenceApplied: "essence_applied"
            case .petEvolved: "pet_evolved"
            case .petArchived: "pet_archived"
            case .breakStarted: "break_started"
            case .breakEnded: "break_ended"
            case .blowAway: "blow_away"
            case .authCompleted: "auth_completed"
            case .paywallShown: "paywall_shown"
            case .purchaseCompleted: "purchase_completed"
            case .purchaseFailed: "purchase_failed"
            case .configChanged: "config_changed"
            case .notificationPermissionResponded: "notification_permission_responded"
            }
        }

        var metadata: [String: String] {
            switch self {
            case .appOpened, .onboardingCompleted:
                [:] as [String: String]
            case .petCreated(let source):
                ["source": source]
            case .presetSelected(let preset, let context):
                ["preset": preset, "context": context.rawValue]
            case .limitedAppsChanged(let appCount):
                ["app_count": "\(appCount)"]
            case .essenceApplied(let essence):
                ["essence": essence]
            case .petEvolved(let essence, let phase):
                ["essence": essence, "phase": "\(phase)"]
            case .petArchived(let essence, let phase, let days, let reason):
                ["essence": essence, "phase": "\(phase)", "days": "\(days)", "reason": reason]
            case .breakStarted(let type, let duration):
                ["type": type, "duration": duration.map { "\($0)" } ?? ""]
            case .breakEnded(let type, let durationMinutes, let success):
                ["type": type, "duration_minutes": "\(durationMinutes)", "success": "\(success)"]
            case .blowAway(let essence, let phase, let days):
                ["essence": essence, "phase": "\(phase)", "days": "\(days)"]
            case .authCompleted(let method):
                ["method": method]
            case .paywallShown(let source, let type):
                ["source": source, "type": type]
            case .purchaseCompleted(let product, let source, let revenue):
                ["product": product, "source": source, "revenue": revenue]
            case .purchaseFailed(let product, let source, let reason):
                ["product": product, "source": source, "reason": reason]
            case .configChanged(let key, let value):
                ["key": key, "value": value]
            case .notificationPermissionResponded(let granted):
                ["granted": "\(granted)"]
            }
        }
    }

    // MARK: - Start

    func start(userId: UUID?) async {
        await StatsigConfig.start(userId: userId?.uuidString)
        isStarted = true
        flushPendingEvents()
    }

    func updateUser(userId: UUID?, premiumPlan: String?) async {
        await StatsigConfig.updateUser(userId: userId?.uuidString, premiumPlan: premiumPlan)
    }

    // MARK: - Sending

    func send(_ event: Event) {
        guard isStarted else {
            pendingEvents.append(event)
            return
        }
        dispatch(event)
    }

    private func dispatch(_ event: Event) {
        Statsig.logEvent(event.name, metadata: event.metadata)
        #if DEBUG
        print("[Analytics] \(event.name) \(event.metadata)")
        #endif
    }

    private func flushPendingEvents() {
        let events = pendingEvents
        pendingEvents.removeAll()
        for event in events {
            dispatch(event)
        }
    }

    // MARK: - Convenience

    func sendBreakStarted(type: String, duration: Int? = nil) {
        send(.breakStarted(type: type, duration: duration))
    }
}
