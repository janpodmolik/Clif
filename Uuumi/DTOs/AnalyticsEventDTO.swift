import Foundation

struct AnalyticsEventDTO: Codable {
    let eventName: String
    let parameters: [String: String]
    let deviceId: String?
    let premiumPlan: String?
    let notificationsEnabled: Bool
    let appVersion: String
    let osVersion: String

    enum CodingKeys: String, CodingKey {
        case eventName = "event_name"
        case parameters
        case deviceId = "device_id"
        case premiumPlan = "premium_plan"
        case notificationsEnabled = "notifications_enabled"
        case appVersion = "app_version"
        case osVersion = "os_version"
    }
}
