import Foundation

/// Centralized scheduling for daily summary and evolution ready notifications.
/// Call `refresh()` on foreground return and settings changes.
enum ScheduledNotificationManager {

    /// Refreshes all scheduled notification state.
    /// - Parameters:
    ///   - isEvolutionAvailable: Whether the pet can evolve right now
    ///   - hasPet: Whether an active pet exists
    ///   - nextEvolutionUnlockDate: The random date when evolution will unlock next
    static func refresh(isEvolutionAvailable: Bool, hasPet: Bool, nextEvolutionUnlockDate: Date? = nil) {
        let settings = SharedDefaults.limitSettings.notifications

        // MARK: - Daily Summary (repeating)

        if hasPet && settings.shouldSendDailySummary() {
            DailySummaryNotification.schedule(
                hour: settings.dailySummaryHour,
                minute: settings.dailySummaryMinute
            )
        } else {
            DailySummaryNotification.cancel()
        }

        // MARK: - Evolution Ready (one-shot, scheduled at random unlock time)

        if hasPet && settings.shouldSendEvolutionReady() {
            if isEvolutionAvailable {
                // Already available — no notification needed
                EvolutionReadyNotification.cancel()
            } else if let unlockDate = nextEvolutionUnlockDate, unlockDate > Date() {
                EvolutionReadyNotification.scheduleAt(unlockDate)
            } else {
                EvolutionReadyNotification.cancel()
            }
        } else {
            EvolutionReadyNotification.cancel()
        }
    }

    /// Cancels all scheduled notifications (e.g., when pet is deleted/archived).
    static func cancelAll() {
        DailySummaryNotification.cancel()
        EvolutionReadyNotification.cancel()
    }
}
