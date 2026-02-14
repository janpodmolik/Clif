import SwiftUI

/// Protocol for different stat types displayed in StatCardView.
/// Allows for extensibility - screen time now, steps/focus later.
protocol StatType {
    var title: String { get }
    var iconName: String { get }
    var primaryValue: String { get }
    var secondaryValue: String? { get }
    var progress: Double? { get }
    var tintColor: Color { get }
}

// MARK: - Screen Time Stat

/// Screen time stat implementation.
struct ScreenTimeStat: StatType {
    let usedMinutes: Int
    let limitMinutes: Int

    var title: String { "Screen Time" }
    var iconName: String { "hourglass" }

    var primaryValue: String {
        formatTime(usedMinutes)
    }

    var secondaryValue: String? {
        "of \(formatTime(limitMinutes))"
    }

    var progress: Double? {
        guard limitMinutes > 0 else { return nil }
        return Double(usedMinutes) / Double(limitMinutes)
    }

    var tintColor: Color {
        guard let progress else { return .blue }
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

// MARK: - Future Stats (Extensibility Examples)

/// Steps stat implementation - for future use.
struct StepsStat: StatType {
    let steps: Int
    let goal: Int

    var title: String { "Steps" }
    var iconName: String { "figure.walk" }
    var primaryValue: String { steps.formatted() }
    var secondaryValue: String? { "Goal: \(goal.formatted())" }
    var progress: Double? { min(Double(steps) / Double(goal), 1.0) }
    var tintColor: Color { .blue }
}

/// Focus time stat implementation - for future use.
struct FocusTimeStat: StatType {
    let focusMinutes: Int
    let goalMinutes: Int

    var title: String { "Focus Time" }
    var iconName: String { "brain.head.profile" }
    var primaryValue: String { "\(focusMinutes)m" }
    var secondaryValue: String? { "Goal: \(goalMinutes)m" }
    var progress: Double? { min(Double(focusMinutes) / Double(goalMinutes), 1.0) }
    var tintColor: Color { .purple }
}
