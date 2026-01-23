import Foundation

/// Event types with associated payload data.
/// Uses enum with associated values for type-safe payload handling.
enum SnapshotEventType: Codable, Equatable {
    /// Usage threshold crossed (cumulative minutes from DeviceActivityMonitor).
    case usageThreshold(cumulativeMinutes: Int)

    /// Break session started. Planned duration is encoded in BreakTypePayload for committed breaks.
    case breakStarted(type: BreakTypePayload)

    /// Break session ended successfully.
    case breakEnded(actualMinutes: Int)

    /// Break session failed (violated).
    case breakFailed(actualMinutes: Int)

    /// Daily reset occurred (midnight rollover).
    case dailyReset

    /// Pet was blown away (wind reached 100 or committed break failed).
    case blowAway

    /// System day start marker.
    case systemDayStart

    /// System day end marker.
    case systemDayEnd

    /// Unknown event type for forward-compatibility.
    case unknown(String)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "event_type"
        case cumulativeMinutes = "cumulative_minutes"
        case breakType = "break_type"
        case actualMinutes = "actual_minutes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "usageThreshold":
            let minutes = try container.decode(Int.self, forKey: .cumulativeMinutes)
            self = .usageThreshold(cumulativeMinutes: minutes)

        case "breakStarted":
            let breakType = try container.decode(BreakTypePayload.self, forKey: .breakType)
            self = .breakStarted(type: breakType)

        case "breakEnded":
            let minutes = try container.decode(Int.self, forKey: .actualMinutes)
            self = .breakEnded(actualMinutes: minutes)

        case "breakFailed":
            let minutes = try container.decode(Int.self, forKey: .actualMinutes)
            self = .breakFailed(actualMinutes: minutes)

        case "dailyReset":
            self = .dailyReset

        case "blowAway":
            self = .blowAway

        case "systemDayStart":
            self = .systemDayStart

        case "systemDayEnd":
            self = .systemDayEnd

        default:
            self = .unknown(type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .usageThreshold(let minutes):
            try container.encode("usageThreshold", forKey: .type)
            try container.encode(minutes, forKey: .cumulativeMinutes)

        case .breakStarted(let breakType):
            try container.encode("breakStarted", forKey: .type)
            try container.encode(breakType, forKey: .breakType)

        case .breakEnded(let minutes):
            try container.encode("breakEnded", forKey: .type)
            try container.encode(minutes, forKey: .actualMinutes)

        case .breakFailed(let minutes):
            try container.encode("breakFailed", forKey: .type)
            try container.encode(minutes, forKey: .actualMinutes)

        case .dailyReset:
            try container.encode("dailyReset", forKey: .type)

        case .blowAway:
            try container.encode("blowAway", forKey: .type)

        case .systemDayStart:
            try container.encode("systemDayStart", forKey: .type)

        case .systemDayEnd:
            try container.encode("systemDayEnd", forKey: .type)

        case .unknown(let value):
            try container.encode(value, forKey: .type)
        }
    }
}

// MARK: - Break Type Payload

/// Break type with duration info. Free breaks have no planned duration.
enum BreakTypePayload: Codable, Equatable {
    case free
    case committed(plannedMinutes: Int)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "break_type"
        case plannedMinutes = "planned_minutes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "free":
            self = .free
        case "committed", "hardcore":
            // "hardcore" mapped to committed for backwards compatibility
            let minutes = try container.decode(Int.self, forKey: .plannedMinutes)
            self = .committed(plannedMinutes: minutes)
        default:
            self = .free // fallback
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .free:
            try container.encode("free", forKey: .type)
        case .committed(let minutes):
            try container.encode("committed", forKey: .type)
            try container.encode(minutes, forKey: .plannedMinutes)
        }
    }
}
