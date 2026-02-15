import Foundation
import Observation
import Supabase

@Observable
final class AnalyticsManager {

    private var isConfigured = false
    private var pendingEvents: [(name: String, parameters: [String: String])] = []
    private var appVersion = ""
    private var osVersion = ""
    private var deviceId: String?
    private var premiumPlan: String?

    private static let queueFileURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("analytics_queue.jsonl")
    }()

    // MARK: - Event Definitions

    enum Event {
        // User actions
        case petCreated(essenceType: String)
        case presetSelected(presetName: String, context: PresetContext)
        case essenceApplied(essenceType: String, evolutionPhase: Int)
        case petEvolved(essenceType: String, fromPhase: Int, toPhase: Int)
        case petArchived(essenceType: String, evolutionPhase: Int, totalDays: Int, reason: String)
        case shieldToggled(enabled: Bool)
        case breakStarted(breakType: String)
        case blowAway(essenceType: String, evolutionPhase: Int, totalDays: Int)
        case premiumPurchaseTapped(plan: String)
        case authCompleted(method: String)
        case feedbackSubmitted

        // Config
        case configSnapshot([String: String])

        enum PresetContext: String {
            case creation
            case daily
        }

        var name: String {
            switch self {
            case .petCreated: "action.petCreated"
            case .presetSelected: "action.presetSelected"
            case .essenceApplied: "action.essenceApplied"
            case .petEvolved: "action.petEvolved"
            case .petArchived: "action.petArchived"
            case .shieldToggled: "action.shieldToggled"
            case .breakStarted: "action.breakStarted"
            case .blowAway: "action.blowAway"
            case .premiumPurchaseTapped: "action.premiumPurchaseTapped"
            case .authCompleted: "action.authCompleted"
            case .feedbackSubmitted: "action.feedbackSubmitted"
            case .configSnapshot: "config.snapshot"
            }
        }

        var parameters: [String: String] {
            switch self {
            case .petCreated(let essenceType):
                ["essenceType": essenceType]
            case .presetSelected(let presetName, let context):
                ["presetName": presetName, "context": context.rawValue]
            case .essenceApplied(let essenceType, let evolutionPhase):
                ["essenceType": essenceType, "evolutionPhase": "\(evolutionPhase)"]
            case .petEvolved(let essenceType, let fromPhase, let toPhase):
                ["essenceType": essenceType, "fromPhase": "\(fromPhase)", "toPhase": "\(toPhase)"]
            case .petArchived(let essenceType, let evolutionPhase, let totalDays, let reason):
                ["essenceType": essenceType, "evolutionPhase": "\(evolutionPhase)", "totalDays": "\(totalDays)", "reason": reason]
            case .shieldToggled(let enabled):
                ["enabled": "\(enabled)"]
            case .breakStarted(let breakType):
                ["breakType": breakType]
            case .blowAway(let essenceType, let evolutionPhase, let totalDays):
                ["essenceType": essenceType, "evolutionPhase": "\(evolutionPhase)", "totalDays": "\(totalDays)"]
            case .premiumPurchaseTapped(let plan):
                ["plan": plan]
            case .authCompleted(let method):
                ["method": method]
            case .feedbackSubmitted:
                [:]
            case .configSnapshot(let params):
                params
            }
        }
    }

    // MARK: - Initialization

    func initialize() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        appVersion = "\(version) (\(build))"
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    }

    // MARK: - Configuration

    func configure(userId: UUID?, premiumPlan: String?) {
        self.deviceId = userId?.uuidString ?? Self.anonymousDeviceId()
        self.premiumPlan = premiumPlan
        self.isConfigured = true
        flushPendingEvents()
    }

    private static func anonymousDeviceId() -> String {
        let key = "analytics_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let deviceId = UUID().uuidString
        UserDefaults.standard.set(deviceId, forKey: key)
        return deviceId
    }

    // MARK: - Sending

    func send(_ event: Event) {
        send(event.name, parameters: event.parameters)
    }

    func send(_ event: String, parameters: [String: String] = [:]) {
        guard isConfigured else {
            pendingEvents.append((name: event, parameters: parameters))
            return
        }

        dispatch(event, parameters: parameters)
    }

    private func flushPendingEvents() {
        let events = pendingEvents
        pendingEvents.removeAll()
        for event in events {
            dispatch(event.name, parameters: event.parameters)
        }
        flushOfflineQueue()
    }

    private func dispatch(_ event: String, parameters: [String: String]) {
        let dto = AnalyticsEventDTO(
            eventName: event,
            parameters: parameters,
            deviceId: deviceId,
            premiumPlan: premiumPlan,
            notificationsEnabled: SharedDefaults.limitSettings.notifications.masterEnabled,
            appVersion: appVersion,
            osVersion: osVersion
        )

        Task { [dto, event] in
            do {
                try await SupabaseConfig.client
                    .from("analytics_events")
                    .insert(dto)
                    .execute()
                #if DEBUG
                print("[Analytics] Sent: \(event)")
                #endif
            } catch {
                Self.persistToQueue(dto)
                #if DEBUG
                print("[Analytics] Queued offline: \(event)")
                #endif
            }
        }
    }

    func sendBreakStarted(breakType: String) {
        send(.breakStarted(breakType: breakType))
        send(.shieldToggled(enabled: true))
    }

    // MARK: - Config Snapshot

    func sendConfigSnapshot() {
        let settings = SharedDefaults.limitSettings
        let notifications = settings.notifications
        let defaults = UserDefaults.standard

        let params: [String: String] = [
            "notif_master": "\(notifications.masterEnabled)",
            "notif_wind25": "\(notifications.windLight)",
            "notif_wind60": "\(notifications.windStrong)",
            "notif_wind85": "\(notifications.windCritical)",
            "notif_breakEnded": "\(notifications.breakCommittedEnded)",
            "notif_windZero": "\(notifications.breakWindZero)",
            "notif_windReminder": "\(notifications.windReminder)",
            "notif_dailySummary": "\(notifications.dailySummary)",
            "notif_evolutionReady": "\(notifications.evolutionReady)",
            "shield_dayStart": "\(settings.dayStartShieldEnabled)",
            "shield_safetyThreshold": "\(settings.safetyShieldActivationThreshold)",
            "shield_safetyUnlock": "\(settings.safetyUnlockThreshold)",
            "shield_autoLock": "\(settings.autoLockAfterCommittedBreak)",
            "appearance": defaults.string(forKey: DefaultsKeys.appearanceMode) ?? "automatic",
            "lockButtonSide": defaults.string(forKey: DefaultsKeys.lockButtonSide) ?? "trailing",
            "theme_day": defaults.string(forKey: DefaultsKeys.selectedDayTheme) ?? "morningHaze",
            "theme_night": defaults.string(forKey: DefaultsKeys.selectedNightTheme) ?? "deepNight",
        ]

        send(.configSnapshot(params))
    }

    // MARK: - Offline Queue

    private static let queueIO = DispatchQueue(label: "com.uuumi.analytics.queue", qos: .utility)

    private static func persistToQueue(_ dto: AnalyticsEventDTO) {
        queueIO.async {
            guard let data = try? JSONEncoder().encode(dto),
                  var line = String(data: data, encoding: .utf8) else { return }
            line.append("\n")

            let url = queueFileURL
            if FileManager.default.fileExists(atPath: url.path) {
                guard let handle = try? FileHandle(forWritingTo: url) else { return }
                try? handle.seekToEnd()
                if let lineData = line.data(using: .utf8) {
                    try? handle.write(contentsOf: lineData)
                }
                try? handle.close()
            } else {
                try? line.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func flushOfflineQueue() {
        let url = Self.queueFileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let content = try? String(contentsOf: url, encoding: .utf8),
              !content.isEmpty else { return }

        let decoder = JSONDecoder()
        let events = content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> AnalyticsEventDTO? in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(AnalyticsEventDTO.self, from: data)
            }

        guard !events.isEmpty else {
            try? FileManager.default.removeItem(at: url)
            return
        }

        Task { [events] in
            for (index, event) in events.enumerated() {
                do {
                    try await SupabaseConfig.client
                        .from("analytics_events")
                        .insert(event)
                        .execute()
                    #if DEBUG
                    print("[Analytics] Flushed: \(event.eventName)")
                    #endif
                } catch {
                    // Re-queue this and all remaining events, stop trying
                    for failedEvent in events[index...] {
                        Self.persistToQueue(failedEvent)
                    }
                    #if DEBUG
                    print("[Analytics] Re-queued \(events.count - index) events (offline)")
                    #endif
                    return
                }
            }
            // All events sent successfully — remove the queue file
            try? FileManager.default.removeItem(at: url)
        }
    }
}
