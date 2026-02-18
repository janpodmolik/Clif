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
    case villain = 2

    // ACT 2: The Demo
    case permission = 3
    case appSelection = 4
    case windSlider = 5
    case lockDemo = 6
    case notifications = 7

    // ACT 3: Setup
    case evolution = 8
    case windPreset = 9
    case namePet = 10
    case placePet = 11

    var id: Int { rawValue }

    var act: OnboardingAct {
        switch self {
        case .island, .meetPet, .villain: .story
        case .permission, .appSelection, .windSlider, .lockDemo, .notifications: .demo
        case .evolution, .windPreset, .namePet, .placePet: .setup
        }
    }

    var title: String {
        switch self {
        case .island: "The Island"
        case .meetPet: "Meet Uuumi"
        case .villain: "Dr. Doomscroll"
        case .permission: "Screen Time Permission"
        case .appSelection: "App Selection"
        case .windSlider: "Feel His Power"
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
        case .villain: "Dr. Doomscroll arrives, wind intensifies"
        case .permission: "FamilyControls authorization prompt"
        case .appSelection: "Screen time data + app picker"
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

    var next: OnboardingScreen? {
        OnboardingScreen(rawValue: rawValue + 1)
    }

    var previous: OnboardingScreen? {
        guard rawValue > 0 else { return nil }
        return OnboardingScreen(rawValue: rawValue - 1)
    }

    static var totalCount: Int { allCases.count }
}
