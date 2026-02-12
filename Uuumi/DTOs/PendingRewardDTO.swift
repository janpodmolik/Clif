import Foundation

/// DTO for the `pending_rewards` Supabase table.
/// Admin inserts rows manually; app claims them on foreground entry.
struct PendingRewardDTO: Codable {
    let id: UUID
    let userId: UUID
    let amount: Int
    let reason: String?
    let createdAt: Date?
    let claimedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case reason
        case createdAt = "created_at"
        case claimedAt = "claimed_at"
    }
}
