import Foundation
import ManagedSettings

// MARK: - Daily Usage Record

/// Daily usage record with unique ID.
struct DailyUsageRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let minutes: Int

    init(id: UUID = UUID(), date: Date, minutes: Int) {
        self.id = id
        self.date = date
        self.minutes = minutes
    }
}

// MARK: - Source Types

/// App source with application token and usage data.
struct AppSource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let applicationToken: ApplicationToken?
    var dailyUsage: [DailyUsageRecord]

    init(
        id: UUID = UUID(),
        displayName: String,
        applicationToken: ApplicationToken? = nil,
        dailyUsage: [DailyUsageRecord] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.applicationToken = applicationToken
        self.dailyUsage = dailyUsage
    }
}

/// Category source with category token and usage data.
struct CategorySource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let categoryToken: ActivityCategoryToken?
    var dailyUsage: [DailyUsageRecord]

    init(
        id: UUID = UUID(),
        displayName: String,
        categoryToken: ActivityCategoryToken? = nil,
        dailyUsage: [DailyUsageRecord] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.categoryToken = categoryToken
        self.dailyUsage = dailyUsage
    }
}

/// Website source with web domain token and usage data.
struct WebsiteSource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let webDomainToken: WebDomainToken?
    var dailyUsage: [DailyUsageRecord]

    init(
        id: UUID = UUID(),
        displayName: String,
        webDomainToken: WebDomainToken? = nil,
        dailyUsage: [DailyUsageRecord] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.webDomainToken = webDomainToken
        self.dailyUsage = dailyUsage
    }
}

// MARK: - LimitedSource Enum

/// Unified model for limited apps, categories, and websites.
enum LimitedSource: Identifiable, Equatable {
    case app(AppSource)
    case category(CategorySource)
    case website(WebsiteSource)

    var id: UUID {
        switch self {
        case .app(let source): source.id
        case .category(let source): source.id
        case .website(let source): source.id
        }
    }

    var displayName: String {
        switch self {
        case .app(let source): source.displayName
        case .category(let source): source.displayName
        case .website(let source): source.displayName
        }
    }

    var dailyUsage: [DailyUsageRecord] {
        switch self {
        case .app(let source): source.dailyUsage
        case .category(let source): source.dailyUsage
        case .website(let source): source.dailyUsage
        }
    }

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

    var kind: Kind {
        switch self {
        case .app: .app
        case .category: .category
        case .website: .website
        }
    }

    var hasToken: Bool {
        switch self {
        case .app(let s): s.applicationToken != nil
        case .category(let s): s.categoryToken != nil
        case .website(let s): s.webDomainToken != nil
        }
    }

    enum Kind: String, Codable {
        case app, category, website
    }
}

// MARK: - Codable

// PropertyList tokens need custom encoding (not JSON-compatible)
private func encodeToken<T: Encodable>(_ token: T?) -> Data? {
    guard let token else { return nil }
    return try? PropertyListEncoder().encode(token)
}

private func decodeToken<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
    guard let data else { return nil }
    return try? PropertyListDecoder().decode(type, from: data)
}

extension AppSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, tokenData, dailyUsage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        dailyUsage = try container.decodeIfPresent([DailyUsageRecord].self, forKey: .dailyUsage) ?? []
        applicationToken = decodeToken(ApplicationToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(dailyUsage, forKey: .dailyUsage)
        try container.encodeIfPresent(encodeToken(applicationToken), forKey: .tokenData)
    }
}

extension CategorySource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, tokenData, dailyUsage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        dailyUsage = try container.decodeIfPresent([DailyUsageRecord].self, forKey: .dailyUsage) ?? []
        categoryToken = decodeToken(ActivityCategoryToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(dailyUsage, forKey: .dailyUsage)
        try container.encodeIfPresent(encodeToken(categoryToken), forKey: .tokenData)
    }
}

extension WebsiteSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, tokenData, dailyUsage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        dailyUsage = try container.decodeIfPresent([DailyUsageRecord].self, forKey: .dailyUsage) ?? []
        webDomainToken = decodeToken(WebDomainToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(dailyUsage, forKey: .dailyUsage)
        try container.encodeIfPresent(encodeToken(webDomainToken), forKey: .tokenData)
    }
}

extension LimitedSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .app: self = .app(try container.decode(AppSource.self, forKey: .data))
        case .category: self = .category(try container.decode(CategorySource.self, forKey: .data))
        case .website: self = .website(try container.decode(WebsiteSource.self, forKey: .data))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        switch self {
        case .app(let source): try container.encode(source, forKey: .data)
        case .category(let source): try container.encode(source, forKey: .data)
        case .website(let source): try container.encode(source, forKey: .data)
        }
    }
}

// MARK: - Token Extraction

extension Array where Element == LimitedSource {
    /// Extracts all application tokens from limited sources.
    var applicationTokens: Set<ApplicationToken> {
        var tokens = Set<ApplicationToken>()
        for source in self {
            if case .app(let appSource) = source, let token = appSource.applicationToken {
                tokens.insert(token)
            }
        }
        return tokens
    }

    /// Extracts all category tokens from limited sources.
    var categoryTokens: Set<ActivityCategoryToken> {
        var tokens = Set<ActivityCategoryToken>()
        for source in self {
            if case .category(let catSource) = source, let token = catSource.categoryToken {
                tokens.insert(token)
            }
        }
        return tokens
    }

    /// Extracts all web domain tokens from limited sources.
    var webDomainTokens: Set<WebDomainToken> {
        var tokens = Set<WebDomainToken>()
        for source in self {
            if case .website(let webSource) = source, let token = webSource.webDomainToken {
                tokens.insert(token)
            }
        }
        return tokens
    }

    /// Whether this collection has any tokens to monitor.
    var hasTokens: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
    }
}

// MARK: - Mock Data

extension LimitedSource {
    static func mockApp(name: String = "Instagram", days: Int = 14) -> LimitedSource {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dailyUsage = (0..<days).map { dayOffset -> DailyUsageRecord in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            return DailyUsageRecord(date: date, minutes: Int.random(in: 5...45))
        }

        return .app(AppSource(displayName: name, dailyUsage: dailyUsage))
    }

    static func mockCategory(name: String = "Social", days: Int = 14) -> LimitedSource {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dailyUsage = (0..<days).map { dayOffset -> DailyUsageRecord in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            return DailyUsageRecord(date: date, minutes: Int.random(in: 10...60))
        }

        return .category(CategorySource(displayName: name, dailyUsage: dailyUsage))
    }

    static func mockWebsite(name: String = "reddit.com", days: Int = 14) -> LimitedSource {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dailyUsage = (0..<days).map { dayOffset -> DailyUsageRecord in
            let date = calendar.date(byAdding: .day, value: -(days - 1) + dayOffset, to: today)!
            return DailyUsageRecord(date: date, minutes: Int.random(in: 5...30))
        }

        return .website(WebsiteSource(displayName: name, dailyUsage: dailyUsage))
    }

    static func mockList(days: Int = 14) -> [LimitedSource] {
        let apps = ["Instagram", "TikTok", "Twitter", "YouTube", "Facebook"]
        let categories = ["Social", "Entertainment"]

        var sources: [LimitedSource] = apps.map { mockApp(name: $0, days: days) }
        sources += categories.map { mockCategory(name: $0, days: days) }

        return sources.sorted { $0.totalMinutes > $1.totalMinutes }
    }
}
