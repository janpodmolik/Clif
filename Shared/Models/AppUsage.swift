import Foundation

/// Daily usage for a specific app.
struct AppDailyUsage: Codable, Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    let minutes: Int

    init(date: Date, minutes: Int) {
        self.date = date
        self.minutes = minutes
    }
}

/// Usage data for a single limited app with daily breakdown.
struct AppUsage: Codable, Identifiable, Equatable {
    let id: UUID
    let petId: UUID
    let displayName: String
    var dailyUsage: [AppDailyUsage]

    var totalMinutes: Int {
        dailyUsage.reduce(0) { $0 + $1.minutes }
    }

    var averageMinutes: Int {
        guard !dailyUsage.isEmpty else { return 0 }
        return totalMinutes / dailyUsage.count
    }

    /// Minutes for a specific date.
    func minutes(for date: Date) -> Int? {
        let calendar = Calendar.current
        return dailyUsage.first { calendar.isDate($0.date, inSameDayAs: date) }?.minutes
    }

    init(id: UUID = UUID(), petId: UUID, displayName: String, dailyUsage: [AppDailyUsage] = []) {
        self.id = id
        self.petId = petId
        self.displayName = displayName
        self.dailyUsage = dailyUsage
    }
}

// MARK: - Mock Data

extension AppUsage {
    static func mock(name: String = "Instagram", days: Int = 14, petId: UUID = UUID()) -> AppUsage {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dailyUsage = (0..<days).map { dayOffset -> AppDailyUsage in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            return AppDailyUsage(date: date, minutes: Int.random(in: 5...45))
        }

        return AppUsage(petId: petId, displayName: name, dailyUsage: dailyUsage)
    }

    static func mockList(days: Int = 14, petId: UUID = UUID()) -> [AppUsage] {
        let apps = ["Instagram", "TikTok", "Twitter", "YouTube", "Facebook"]
        return apps.map { name in
            mock(name: name, days: days, petId: petId)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }
}
