import Foundation

/// Event types with associated payload data.
/// Uses enum with associated values for type-safe payload handling.
enum SnapshotEventType: Codable, Equatable {
    /// Usage threshold crossed (cumulative seconds from DeviceActivityMonitor).
    case usageThreshold(cumulativeSeconds: Int)

    /// Break session started. Planned duration is encoded in BreakTypePayload for committed breaks.
    case breakStarted(type: BreakTypePayload)

    /// Break session ended. Success indicates whether the break was completed without violation.
    case breakEnded(actualMinutes: Int, success: Bool)

    /// Daily reset occurred (midnight rollover).
    case dailyReset

    /// Pet was blown away (wind reached 100 or committed break failed).
    case blowAway(reason: BlowAwayReason)

    /// System day start marker.
    case systemDayStart

    /// System day end marker.
    case systemDayEnd

    /// Daily preset was selected.
    case presetSelected(preset: String)

    /// Unknown event type for forward-compatibility.
    case unknown(String)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type = "event_type"
        case cumulativeSeconds = "cumulative_seconds"
        case breakType = "break_type"
        case actualMinutes = "actual_minutes"
        case success
        case blowAwayReason = "blow_away_reason"
        case preset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "usageThreshold":
            let seconds = try container.decode(Int.self, forKey: .cumulativeSeconds)
            self = .usageThreshold(cumulativeSeconds: seconds)

        case "breakStarted":
            let breakType = try container.decode(BreakTypePayload.self, forKey: .breakType)
            self = .breakStarted(type: breakType)

        case "breakEnded":
            let minutes = try container.decode(Int.self, forKey: .actualMinutes)
            let success = try container.decode(Bool.self, forKey: .success)
            self = .breakEnded(actualMinutes: minutes, success: success)

        case "dailyReset":
            self = .dailyReset

        case "blowAway":
            let reason = try container.decodeIfPresent(BlowAwayReason.self, forKey: .blowAwayReason) ?? .limitExceeded
            self = .blowAway(reason: reason)

        case "systemDayStart":
            self = .systemDayStart

        case "systemDayEnd":
            self = .systemDayEnd

        case "presetSelected":
            let preset = try container.decode(String.self, forKey: .preset)
            self = .presetSelected(preset: preset)

        default:
            self = .unknown(type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .usageThreshold(let seconds):
            try container.encode("usageThreshold", forKey: .type)
            try container.encode(seconds, forKey: .cumulativeSeconds)

        case .breakStarted(let breakType):
            try container.encode("breakStarted", forKey: .type)
            try container.encode(breakType, forKey: .breakType)

        case .breakEnded(let minutes, let success):
            try container.encode("breakEnded", forKey: .type)
            try container.encode(minutes, forKey: .actualMinutes)
            try container.encode(success, forKey: .success)

        case .dailyReset:
            try container.encode("dailyReset", forKey: .type)

        case .blowAway(let reason):
            try container.encode("blowAway", forKey: .type)
            try container.encode(reason, forKey: .blowAwayReason)

        case .systemDayStart:
            try container.encode("systemDayStart", forKey: .type)

        case .systemDayEnd:
            try container.encode("systemDayEnd", forKey: .type)

        case .presetSelected(let preset):
            try container.encode("presetSelected", forKey: .type)
            try container.encode(preset, forKey: .preset)

        case .unknown(let value):
            try container.encode(value, forKey: .type)
        }
    }

    /// Whether this is a blowAway event (any reason).
    var isBlowAway: Bool {
        if case .blowAway = self { return true }
        return false
    }

    /// Returns the blow away reason if this is a blowAway event.
    var blowAwayReason: BlowAwayReason? {
        if case .blowAway(let reason) = self { return reason }
        return nil
    }

    /// Returns the preset raw value if this is a presetSelected event.
    var presetValue: String? {
        if case .presetSelected(let preset) = self { return preset }
        return nil
    }
}

// MARK: - Blow Away Reason

/// Reason why pet was blown away.
enum BlowAwayReason: String, Codable {
    /// Wind reached 100% from exceeding screen time limit.
    case limitExceeded = "limit_exceeded"
    /// User violated a committed break by opening a shielded app.
    case breakViolation = "break_violation"
    /// User chose to blow away their pet voluntarily.
    case userChoice = "user_choice"

    var label: String {
        switch self {
        case .limitExceeded: "Překročen limit"
        case .breakViolation: "Porušena pauza"
        case .userChoice: "Vlastní volba"
        }
    }

    var description: String {
        switch self {
        case .limitExceeded: "Pet byl odfouknut, protože jsi překročil/a denní limit."
        case .breakViolation: "Pet byl odfouknut, protože jsi porušil/a závaznou pauzu."
        case .userChoice: "Pet byl odfouknut na tvé vlastní přání."
        }
    }

    var icon: String {
        switch self {
        case .limitExceeded: "exclamationmark.triangle.fill"
        case .breakViolation: "hand.raised.slash.fill"
        case .userChoice: "hand.tap"
        }
    }
}

// MARK: - Break Type Payload

/// Break type with duration info. Free breaks have no planned duration.
enum BreakTypePayload: Codable, Equatable {
    case free
    case committed(plannedMinutes: Int)
    case safety

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
        case "safety":
            self = .safety
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
        case .safety:
            try container.encode("safety", forKey: .type)
        }
    }
}
