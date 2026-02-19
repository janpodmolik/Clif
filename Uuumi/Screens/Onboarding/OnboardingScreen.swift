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

    // ACT 2: The Demo
    case windSlider = 3
    case lockDemo = 4
    case notifications = 5

    // ACT 3: Setup
    case evolution = 6
    case windPreset = 7
    case namePet = 8
    case placePet = 9

    var id: Int { rawValue }

    var act: OnboardingAct {
        switch self {
        case .island, .meetPet, .wind: .story
        case .windSlider, .lockDemo, .notifications: .demo
        case .evolution, .windPreset, .namePet, .placePet: .setup
        }
    }

    var title: String {
        switch self {
        case .island: "The Island"
        case .meetPet: "Meet Uuumi"
        case .wind: "The Wind"
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
        case .wind: "Wind mechanic intro + Screen Time permission + data preview"
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

    /// Whether wind effects should be visible on this screen and beyond.
    var showsWind: Bool {
        switch self {
        case .wind, .windSlider, .lockDemo: true
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
