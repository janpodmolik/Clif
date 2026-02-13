import Foundation

/// Centralized scheduling for daily summary and evolution ready notifications.
/// Call `refresh()` on foreground return and settings changes.
enum ScheduledNotificationManager {

    /// Refreshes all scheduled notification state.
    /// - Parameters:
    ///   - isEvolutionAvailable: Whether the pet can evolve right now
    ///   - hasPet: Whether an active pet exists
    static func refresh(isEvolutionAvailable: Bool, hasPet: Bool) {
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

        // MARK: - Evolution Ready (one-shot, only if can evolve)

        if hasPet && isEvolutionAvailable && settings.shouldSendEvolutionReady() {
            EvolutionReadyNotification.scheduleNext(
                hour: settings.evolutionReadyHour,
                minute: settings.evolutionReadyMinute
            )
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
