import Foundation

struct FeedbackDTO: Codable {
    let userId: UUID?
    let message: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
        case appVersion = "app_version"
    }
}
