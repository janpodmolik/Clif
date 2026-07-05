import Foundation

enum OnboardingScreen: Int, CaseIterable, Identifiable {
    // ACT 1: The Story
    case island = 0
    case meetPet = 1
    case wind = 2
    case screenTimeData = 3
    case appSelection = 4

    // ACT 2: The Demo
    case windSlider = 5
    case lockDemo = 6

    // ACT 3: Setup
    case windPreset = 7
    case essence = 8
    case evolution = 9
    case notifications = 10
    case namePet = 11
    case login = 12

    var id: Int { rawValue }

    var isLast: Bool { self == .login }

    /// The wind progress value this screen expects on entry.
    /// Used by `goBack()` and step `onAppear` to set consistent initial state.
    var initialWindProgress: CGFloat? {
        switch self {
        case .wind, .screenTimeData: 0.15
        case .windSlider: 0.1
        case .lockDemo: 1.0
        case .windPreset, .essence, .evolution, .notifications, .namePet, .login: 0
        default: nil
        }
    }

    /// Whether wind effects should be visible on this screen and beyond.
    var showsWind: Bool {
        switch self {
        case .wind, .screenTimeData, .windSlider, .lockDemo: true
        default: false
        }
    }

    var next: OnboardingScreen? {
        OnboardingScreen(rawValue: rawValue + 1)
    }

    var previous: OnboardingScreen? {
        guard rawValue > 0 else { return nil }
        return OnboardingScreen(rawValue: rawValue - 1)
    }

    static var totalCount: Int { allCases.count }
}
