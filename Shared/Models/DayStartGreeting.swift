import Foundation

/// Greeting configuration for Day Start Shield, shared between SwiftUI and UIKit.
/// Provides dynamic greeting text and icon based on time of day.
enum DayStartGreeting {
    /// Hour threshold for morning greeting (before this hour = "Dobré ráno!")
    private static let morningHourLimit = 10

    /// Returns appropriate greeting text based on current hour.
    /// "Dobré ráno!" before 10:00, "Ahoj!" otherwise.
    static var text: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < morningHourLimit ? "Dobré ráno!" : "Ahoj!"
    }

    /// Returns SF Symbol name for greeting icon.
    /// "sun.horizon.fill" for morning, "hand.wave.fill" otherwise.
    static var iconName: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < morningHourLimit ? "sun.horizon.fill" : "hand.wave.fill"
    }

    /// Returns true if current time is considered morning (before morningHourLimit).
    static var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < morningHourLimit
    }
}
