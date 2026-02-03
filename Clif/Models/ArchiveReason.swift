enum ArchiveReason: String, Codable {
    case blown      // Wind reached 100% or break violation
    case completed  // Fully evolved (phase 4), user archived
    case lost       // Tokens invalid (reinstall, revoked access)
    case manual     // User archived pet before full evolution
}
