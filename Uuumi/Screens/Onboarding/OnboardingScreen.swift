import Foundation

enum OnboardingAct: Int, CaseIterable {
    case story = 1
    case demo = 2
    case setup = 3

    var title: String {
        switch self {
        case .story: "The Story"
        case .demo: "The Demo"
        case .setup: "Setup"
        }
    }
}

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
    case evolution = 8
    case notifications = 9
    case namePet = 10
    case placePet = 11

    var id: Int { rawValue }

    var act: OnboardingAct {
        switch self {
        case .island, .meetPet, .wind, .screenTimeData, .appSelection: .story
        case .windSlider, .lockDemo: .demo
        case .evolution, .notifications, .windPreset, .namePet, .placePet: .setup
        }
    }

    var title: String {
        switch self {
        case .island: "The Island"
        case .meetPet: "Meet Uuumi"
        case .wind: "The Wind"
        case .screenTimeData: "Screen Time"
        case .appSelection: "Your Apps"
        case .windSlider: "Feel The Wind"
        case .lockDemo: "The Lock"
        case .notifications: "Notifications"
        case .evolution: "Evolution"
        case .windPreset: "Wind Preset"
        case .namePet: "Name Your Pet"
        case .placePet: "Place On The Island"
        }
    }

    var description: String {
        switch self {
        case .island: "Empty floating island, serene atmosphere"
        case .meetPet: "Blob appears, user taps to interact"
        case .wind: "Wind mechanic intro + Screen Time permission"
        case .screenTimeData: "Screen time data reveal with horizontal app carousel"
        case .appSelection: "Choose which apps create the wind"
        case .windSlider: "Interactive slider driving wind intensity"
        case .lockDemo: "Tap lock to stop the wind"
        case .notifications: "Mock notifications + permission prompt"
        case .evolution: "Evolution paths preview"
        case .windPreset: "Gentle / Balanced / Intense cards"
        case .namePet: "Text field for pet name"
        case .placePet: "Drag & drop blob onto island"
        }
    }

    var isLast: Bool { self == .placePet }

    /// The wind progress value this screen expects on entry.
    /// Used by `goBack()` and step `onAppear` to set consistent initial state.
    var initialWindProgress: CGFloat? {
        switch self {
        case .wind, .screenTimeData: 0.15
        case .windSlider: 0.1
        case .lockDemo: 0.7
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
