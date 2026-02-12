import Foundation

struct PetSearchFilter: Equatable {
    var searchText: String = ""
    var dateRange: DateRange = .all
    var customStartDate: Date?
    var customEndDate: Date?
    var statusFilter: StatusFilter = .all
    var essenceFilter: Set<Essence> = Set(Essence.allCases)
    var minDuration: Int = 0
    var maxDuration: Int = 60

    static let durationRange: ClosedRange<Int> = 0...60

    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        dateRange != .all ||
        statusFilter != .all ||
        essenceFilter != Set(Essence.allCases) ||
        isDurationFiltered
    }

    var isDurationFiltered: Bool {
        minDuration > Self.durationRange.lowerBound ||
        maxDuration < Self.durationRange.upperBound
    }

    var durationLabel: String {
        if minDuration == 0 && maxDuration >= 60 {
            return "Vše"
        } else if maxDuration >= 60 {
            return "\(minDuration)+ dní"
        } else if minDuration == 0 {
            return "do \(maxDuration) dní"
        } else {
            return "\(minDuration)-\(maxDuration) dní"
        }
    }

    var activeFilterCount: Int {
        var count = 0
        if dateRange != .all { count += 1 }
        if statusFilter != .all { count += 1 }
        if essenceFilter != Set(Essence.allCases) { count += 1 }
        if isDurationFiltered { count += 1 }
        return count
    }

    func matchesDuration(days: Int) -> Bool {
        let effectiveMax = maxDuration >= 60 ? Int.max : maxDuration
        return days >= minDuration && days <= effectiveMax
    }

    mutating func reset() {
        searchText = ""
        dateRange = .all
        customStartDate = nil
        customEndDate = nil
        statusFilter = .all
        essenceFilter = Set(Essence.allCases)
        minDuration = Self.durationRange.lowerBound
        maxDuration = Self.durationRange.upperBound
    }
}

// MARK: - Filter Enums

extension PetSearchFilter {
    enum DateRange: String, CaseIterable, Identifiable {
        case all = "Vše"
        case lastWeek = "Poslední týden"
        case lastMonth = "Poslední měsíc"
        case last3Months = "Poslední 3 měsíce"
        case lastYear = "Poslední rok"
        case custom = "Vlastní rozsah"

        var id: String { rawValue }

        func dateInterval(customStart: Date?, customEnd: Date?) -> DateInterval? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .all:
                return nil
            case .lastWeek:
                let start = calendar.date(byAdding: .day, value: -7, to: now)!
                return DateInterval(start: start, end: now)
            case .lastMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                return DateInterval(start: start, end: now)
            case .last3Months:
                let start = calendar.date(byAdding: .month, value: -3, to: now)!
                return DateInterval(start: start, end: now)
            case .lastYear:
                let start = calendar.date(byAdding: .year, value: -1, to: now)!
                return DateInterval(start: start, end: now)
            case .custom:
                guard let start = customStart, let end = customEnd else { return nil }
                return DateInterval(start: start, end: end)
            }
        }
    }

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "Všichni"
        case completed = "Dokončení"
        case blownAway = "Odfouknutí"
        case manual = "Archivovaní"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: "list.bullet"
            case .completed: "checkmark.circle.fill"
            case .blownAway: "wind"
            case .manual: "archivebox"
            }
        }

        /// The ArchiveReason this filter matches, if any.
        var matchingReason: ArchiveReason? {
            switch self {
            case .all: nil
            case .completed: .completed
            case .blownAway: .blown
            case .manual: .manual
            }
        }
    }

}
