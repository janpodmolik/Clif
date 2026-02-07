import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable {
    case automatic, light, dark

    var label: String {
        switch self {
        case .automatic: "Automatický"
        case .light: "Světlý"
        case .dark: "Tmavý"
        }
    }

    var icon: String {
        switch self {
        case .automatic: "clock"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}

enum DayTheme: String, CaseIterable, Codable, Identifiable {
    case morningHaze
    case clearSky

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morningHaze: "Ranní opár"
        case .clearSky: "Jasné nebe"
        }
    }

    var gradient: [Color] {
        switch self {
        case .morningHaze:
            [
                Color(red: 0.68, green: 0.75, blue: 0.85),
                Color(red: 0.78, green: 0.80, blue: 0.85),
                Color(red: 0.90, green: 0.85, blue: 0.82),
                Color(red: 0.93, green: 0.82, blue: 0.75),
            ]
        case .clearSky:
            [
                Color(red: 0.55, green: 0.70, blue: 0.90),
                Color(red: 0.65, green: 0.78, blue: 0.92),
                Color(red: 0.80, green: 0.88, blue: 0.95),
                Color(red: 0.90, green: 0.92, blue: 0.95),
            ]
        }
    }
}

enum NightTheme: String, CaseIterable, Codable, Identifiable {
    case deepNight
    case twilight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .deepNight: "Hluboká noc"
        case .twilight: "Soumrak"
        }
    }

    var gradient: [Color] {
        switch self {
        case .deepNight:
            [
                Color(red: 0.05, green: 0.05, blue: 0.22),
                Color(red: 0.12, green: 0.12, blue: 0.38),
                Color(red: 0.30, green: 0.25, blue: 0.55),
            ]
        case .twilight:
            [
                Color(red: 0.12, green: 0.10, blue: 0.30),
                Color(red: 0.25, green: 0.18, blue: 0.45),
                Color(red: 0.45, green: 0.30, blue: 0.55),
                Color(red: 0.55, green: 0.35, blue: 0.50),
            ]
        }
    }
}
