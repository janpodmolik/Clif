import SwiftUI

// MARK: - Sky Colors

extension Color {
    // Derived from static themes:
    //   midnight ≈ deepNight, sunrise ≈ morningHaze, day ≈ clearSky, sunset ≈ twilight

    // Layer 1 (top of screen)
    static let skyMidnight1 = Color(red: 0.04, green: 0.04, blue: 0.20)
    static let skySunrise1 = Color(red: 0.68, green: 0.75, blue: 0.85)
    static let skySunnyDay1 = Color(red: 0.55, green: 0.70, blue: 0.90)
    static let skySunset1 = Color(red: 0.12, green: 0.10, blue: 0.30)

    // Layer 2 (upper-middle)
    static let skyMidnight2 = Color(red: 0.08, green: 0.07, blue: 0.30)
    static let skySunrise2 = Color(red: 0.78, green: 0.80, blue: 0.85)
    static let skySunnyDay2 = Color(red: 0.65, green: 0.78, blue: 0.92)
    static let skySunset2 = Color(red: 0.25, green: 0.18, blue: 0.45)

    // Layer 3 (lower-middle)
    static let skyMidnight3 = Color(red: 0.15, green: 0.12, blue: 0.40)
    static let skySunrise3 = Color(red: 0.90, green: 0.85, blue: 0.82)
    static let skySunnyDay3 = Color(red: 0.80, green: 0.88, blue: 0.95)
    static let skySunset3 = Color(red: 0.45, green: 0.30, blue: 0.55)

    // Layer 4 (bottom of screen)
    static let skyMidnight4 = Color(red: 0.22, green: 0.18, blue: 0.48)
    static let skySunrise4 = Color(red: 0.93, green: 0.82, blue: 0.75)
    static let skySunnyDay4 = Color(red: 0.90, green: 0.92, blue: 0.95)
    static let skySunset4 = Color(red: 0.55, green: 0.35, blue: 0.50)
}

// MARK: - SkyGradient

struct SkyGradient {

    /// Duration of sunrise/sunset transitions in hours.
    private static let transitionHours: Double = 2

    // MARK: - Approximate sunrise/sunset for CZ latitude (~50°N)
    // Each entry is (sunrise hour, sunset hour) for the middle of months Jan–Dec.
    private static let sunTable: [(rise: Double, set: Double)] = [
        (7.75, 16.25),  // Jan
        (7.00, 17.25),  // Feb
        (6.25, 18.25),  // Mar
        (5.50, 19.25),  // Apr  (DST)
        (5.00, 20.25),  // May
        (4.75, 21.00),  // Jun
        (5.00, 21.00),  // Jul
        (5.50, 20.25),  // Aug
        (6.25, 19.25),  // Sep
        (7.00, 18.00),  // Oct  (DST ends late Oct)
        (7.00, 16.50),  // Nov
        (7.50, 16.00),  // Dec
    ]

    /// Approximate sunrise hour for today, linearly interpolated between months.
    private static var sunriseHour: Double { interpolatedSunTime(\.rise) }

    /// Approximate sunset hour for today, linearly interpolated between months.
    private static var sunsetHour: Double { interpolatedSunTime(\.set) }

    private static func interpolatedSunTime(_ keyPath: KeyPath<(rise: Double, set: Double), Double>) -> Double {
        let cal = Calendar.current
        let now = Date.now
        let month = cal.component(.month, from: now)       // 1-12
        let day = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30

        let currentIndex = month - 1
        let nextIndex = month % 12
        let fraction = Double(day - 1) / Double(daysInMonth)

        let current = sunTable[currentIndex][keyPath: keyPath]
        let next = sunTable[nextIndex][keyPath: keyPath]
        return current + (next - current) * fraction
    }

    // MARK: - Dynamic stops

    /// Builds gradient stops for a single layer from its midnight/sunrise/day/sunset colors.
    /// Timeline: midnight → (hold) → sunrise transition (2h) → day → (hold) → sunset transition (2h) → midnight
    private static func makeStops(midnight: Color, sunrise: Color, day: Color, sunset: Color) -> [Gradient.Stop] {
        let rise = sunriseHour / 24          // start of sunrise transition
        let riseEnd = rise + transitionHours / 24  // end of sunrise → becomes day
        let setStart = sunsetHour / 24       // start of sunset transition
        let setEnd = setStart + transitionHours / 24  // end of sunset → becomes night

        return [
            .init(color: midnight, location: 0),
            .init(color: midnight, location: rise),
            .init(color: sunrise,  location: rise + (riseEnd - rise) * 0.5),
            .init(color: day,      location: riseEnd),
            .init(color: day,      location: setStart),
            .init(color: sunset,   location: setStart + (setEnd - setStart) * 0.5),
            .init(color: midnight, location: setEnd),
            .init(color: midnight, location: 1),
        ]
    }

    static var layer1Stops: [Gradient.Stop] {
        makeStops(midnight: .skyMidnight1, sunrise: .skySunrise1, day: .skySunnyDay1, sunset: .skySunset1)
    }

    static var layer2Stops: [Gradient.Stop] {
        makeStops(midnight: .skyMidnight2, sunrise: .skySunrise2, day: .skySunnyDay2, sunset: .skySunset2)
    }

    static var layer3Stops: [Gradient.Stop] {
        makeStops(midnight: .skyMidnight3, sunrise: .skySunrise3, day: .skySunnyDay3, sunset: .skySunset3)
    }

    static var layer4Stops: [Gradient.Stop] {
        makeStops(midnight: .skyMidnight4, sunrise: .skySunrise4, day: .skySunnyDay4, sunset: .skySunset4)
    }

    static var starOpacityStops: [Gradient.Stop] {
        let rise = sunriseHour / 24
        let riseEnd = rise + transitionHours / 24
        let setStart = sunsetHour / 24
        let setEnd = setStart + transitionHours / 24

        return [
            .init(color: .white, location: 0),
            .init(color: .white, location: rise),
            .init(color: .clear, location: riseEnd),
            .init(color: .clear, location: setStart),
            .init(color: .white, location: setEnd),
            .init(color: .white, location: 1),
        ]
    }

    // MARK: - Utilities

    /// Returns the current time of day as a value from 0.0 (midnight) to 1.0 (next midnight).
    static func timeOfDay() -> Double {
        let now = Date.now
        let startOfDay = Calendar.current.startOfDay(for: now)
        return now.timeIntervalSince(startOfDay) / 86400
    }

    /// Whether it's currently daytime (between end of sunrise and start of sunset).
    static func isDaytime() -> Bool {
        let time = timeOfDay()
        let riseEnd = sunriseHour / 24 + transitionHours / 24
        let setStart = sunsetHour / 24
        return time > riseEnd && time < setStart
    }

    /// Star opacity for the given time (0 = invisible, 1 = fully visible).
    static func starOpacity(at time: Double) -> Double {
        let color = starOpacityStops.interpolated(amount: time)
        return color.getComponents().alpha
    }
}
