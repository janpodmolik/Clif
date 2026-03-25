import BackgroundTasks
import ManagedSettings

/// Schedules a BGAppRefreshTask near midnight to ensure the day-start shield
/// is activated even if the DeviceActivityMonitor extension doesn't fire.
enum MidnightShieldTask {

    static let identifier = "com.janpodmolik.Uuumi.midnightShield"

    /// Registers the background task handler. Must be called before app finishes launching.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleTask(refreshTask)
        }
    }

    /// Schedules the task for start of next calendar day.
    /// Safe to call multiple times — iOS replaces any existing pending request.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[MidnightShieldTask] Scheduled for \(request.earliestBeginDate?.description ?? "nil")")
            #endif
        } catch {
            #if DEBUG
            print("[MidnightShieldTask] Failed to schedule: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Private

    private static func handleTask(_ task: BGAppRefreshTask) {
        // Schedule next occurrence immediately
        schedule()

        guard SharedDefaults.isNewDay else {
            task.setTaskCompleted(success: true)
            return
        }

        SharedDefaults.performDailyResetIfNeeded()

        // Activate shield from stored tokens (same pattern as extension)
        let store = ManagedSettingsStore()
        let appTokens = SharedDefaults.loadApplicationTokens() ?? []
        let catTokens = SharedDefaults.loadCategoryTokens() ?? []
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? []

        if !appTokens.isEmpty {
            store.shield.applications = appTokens
        }
        if !catTokens.isEmpty {
            store.shield.applicationCategories = .specific(catTokens, except: Set())
        }
        if !webTokens.isEmpty {
            store.shield.webDomains = webTokens
        }

        #if DEBUG
        print("[MidnightShieldTask] Daily reset + shield activated")
        #endif

        task.setTaskCompleted(success: true)
    }
}
