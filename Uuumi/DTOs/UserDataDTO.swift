import Foundation

/// DTO for the `user_data` Supabase table.
/// One row per user with a JSONB `data` column containing all syncable user state.
struct UserDataDTO: Codable {
    let userId: UUID
    let data: UserDataPayload
    let schemaVersion: Int
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case data
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
    }

    /// Captures current local state into a DTO for upload.
    /// Note: Only explicitly unlocked essences are synced — default essences
    /// (see `Essence.defaultUnlocked`) are always available via code and don't
    /// need cloud backup. This avoids migration issues if defaults change.
    static func fromLocal(userId: UUID, essenceCatalogManager: EssenceCatalogManager) -> UserDataDTO {
        UserDataDTO(
            userId: userId,
            data: UserDataPayload(
                coinsBalance: SharedDefaults.coinsBalance,
                unlockedEssences: essenceCatalogManager.unlockedEssences.map(\.rawValue),
                limitSettings: SharedDefaults.limitSettings
            ),
            schemaVersion: 1,
            updatedAt: Date()
        )
    }
}

/// The JSONB content of the `data` column.
struct UserDataPayload: Codable {
    var coinsBalance: Int
    var unlockedEssences: [String]
    var limitSettings: LimitSettings
}
