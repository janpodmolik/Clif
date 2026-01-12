import Foundation
import ManagedSettings

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
struct AppUsage: Identifiable, Equatable {
    let id: UUID
    let petId: UUID
    let displayName: String
    let applicationToken: ApplicationToken?
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

    init(
        id: UUID = UUID(),
        petId: UUID,
        displayName: String,
        applicationToken: ApplicationToken? = nil,
        dailyUsage: [AppDailyUsage] = []
    ) {
        self.id = id
        self.petId = petId
        self.displayName = displayName
        self.applicationToken = applicationToken
        self.dailyUsage = dailyUsage
    }
}

// MARK: - Codable

extension AppUsage: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, petId, displayName, applicationTokenData, dailyUsage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        petId = try container.decode(UUID.self, forKey: .petId)
        displayName = try container.decode(String.self, forKey: .displayName)
        dailyUsage = try container.decode([AppDailyUsage].self, forKey: .dailyUsage)

        if let tokenData = try container.decodeIfPresent(Data.self, forKey: .applicationTokenData) {
            applicationToken = try? PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
        } else {
            applicationToken = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(petId, forKey: .petId)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(dailyUsage, forKey: .dailyUsage)

        if let token = applicationToken,
           let tokenData = try? PropertyListEncoder().encode(token) {
            try container.encode(tokenData, forKey: .applicationTokenData)
        }
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
