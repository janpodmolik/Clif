import FamilyControls
import Foundation
import ManagedSettings

// MARK: - Source Types

/// App source with application token.
struct AppSource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let applicationToken: ApplicationToken?

    init(
        id: UUID = UUID(),
        displayName: String,
        applicationToken: ApplicationToken? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.applicationToken = applicationToken
    }
}

/// Category source with category token.
struct CategorySource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let categoryToken: ActivityCategoryToken?

    init(
        id: UUID = UUID(),
        displayName: String,
        categoryToken: ActivityCategoryToken? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.categoryToken = categoryToken
    }
}

/// Website source with web domain token.
struct WebsiteSource: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let webDomainToken: WebDomainToken?

    init(
        id: UUID = UUID(),
        displayName: String,
        webDomainToken: WebDomainToken? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.webDomainToken = webDomainToken
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
        case id, displayName, tokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        applicationToken = decodeToken(ApplicationToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(encodeToken(applicationToken), forKey: .tokenData)
    }
}

extension CategorySource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, tokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        categoryToken = decodeToken(ActivityCategoryToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(encodeToken(categoryToken), forKey: .tokenData)
    }
}

extension WebsiteSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, displayName, tokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        webDomainToken = decodeToken(WebDomainToken.self, from: try container.decodeIfPresent(Data.self, forKey: .tokenData))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
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
    /// Extracts application tokens in stable order (for display).
    var orderedApplicationTokens: [ApplicationToken] {
        compactMap { source in
            if case .app(let appSource) = source { return appSource.applicationToken }
            return nil
        }
    }

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

// MARK: - FamilyActivitySelection Conversion

extension LimitedSource {
    /// Converts a FamilyActivitySelection into an array of LimitedSource.
    static func from(_ selection: FamilyActivitySelection) -> [LimitedSource] {
        var sources: [LimitedSource] = []

        for token in selection.applicationTokens {
            sources.append(.app(AppSource(displayName: "App", applicationToken: token)))
        }

        for token in selection.categoryTokens {
            sources.append(.category(CategorySource(displayName: "Category", categoryToken: token)))
        }

        for token in selection.webDomainTokens {
            sources.append(.website(WebsiteSource(displayName: "Website", webDomainToken: token)))
        }

        return sources
    }
}

// MARK: - Mock Data

extension LimitedSource {
    static func mockApp(name: String = "Instagram") -> LimitedSource {
        .app(AppSource(displayName: name))
    }

    static func mockCategory(name: String = "Social") -> LimitedSource {
        .category(CategorySource(displayName: name))
    }

    static func mockWebsite(name: String = "reddit.com") -> LimitedSource {
        .website(WebsiteSource(displayName: name))
    }

    static func mockList() -> [LimitedSource] {
        let apps = ["Instagram", "TikTok", "Twitter", "YouTube", "Facebook"]
        let categories = ["Social", "Entertainment"]

        var sources: [LimitedSource] = apps.map { mockApp(name: $0) }
        sources += categories.map { mockCategory(name: $0) }

        return sources
    }
}
