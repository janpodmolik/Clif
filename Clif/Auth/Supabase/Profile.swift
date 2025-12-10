import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var username: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
    }
}

enum ProfileError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Uživatel není přihlášen"
        case .profileNotFound:
            return "Profil nenalezen"
        }
    }
}
