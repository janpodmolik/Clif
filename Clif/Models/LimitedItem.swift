import Foundation
import ManagedSettings

/// A limited app with display name and optional token for icon display.
struct LimitedApp: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let applicationToken: ApplicationToken?

    init(id: UUID = UUID(), displayName: String, applicationToken: ApplicationToken? = nil) {
        self.id = id
        self.displayName = displayName
        self.applicationToken = applicationToken
    }
}

/// A limited category with display name and optional token for icon display.
struct LimitedCategory: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let categoryToken: ActivityCategoryToken?

    init(id: UUID = UUID(), displayName: String, categoryToken: ActivityCategoryToken? = nil) {
        self.id = id
        self.displayName = displayName
        self.categoryToken = categoryToken
    }
}

// MARK: - Codable

extension LimitedApp: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, applicationTokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)

        if let tokenData = try container.decodeIfPresent(Data.self, forKey: .applicationTokenData) {
            applicationToken = try? PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
        } else {
            applicationToken = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)

        if let token = applicationToken,
           let tokenData = try? PropertyListEncoder().encode(token) {
            try container.encode(tokenData, forKey: .applicationTokenData)
        }
    }
}

extension LimitedCategory: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, categoryTokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)

        if let tokenData = try container.decodeIfPresent(Data.self, forKey: .categoryTokenData) {
            categoryToken = try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: tokenData)
        } else {
            categoryToken = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)

        if let token = categoryToken,
           let tokenData = try? PropertyListEncoder().encode(token) {
            try container.encode(tokenData, forKey: .categoryTokenData)
        }
    }
}

// MARK: - Mock Data

extension LimitedApp {
    static func mock(name: String = "Instagram") -> LimitedApp {
        LimitedApp(displayName: name)
    }

    static func mockList() -> [LimitedApp] {
        ["Instagram", "TikTok", "Twitter", "YouTube", "Facebook"].map { .mock(name: $0) }
    }
}

extension LimitedCategory {
    static func mock(name: String = "Social") -> LimitedCategory {
        LimitedCategory(displayName: name)
    }

    static func mockList() -> [LimitedCategory] {
        ["Social", "Entertainment"].map { .mock(name: $0) }
    }
}
