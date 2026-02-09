import Foundation

extension SharedDefaults {

    /// Cached hourly usage aggregate. Nil if not yet computed.
    static var hourlyAggregate: HourlyAggregate? {
        get {
            guard let data = defaults?.data(forKey: DefaultsKeys.hourlyAggregate) else { return nil }
            return try? JSONDecoder().decode(HourlyAggregate.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults?.set(data, forKey: DefaultsKeys.hourlyAggregate)
                defaults?.set(todayString, forKey: DefaultsKeys.hourlyAggregateDate)
            } else {
                defaults?.removeObject(forKey: DefaultsKeys.hourlyAggregate)
                defaults?.removeObject(forKey: DefaultsKeys.hourlyAggregateDate)
            }
        }
    }

    /// Whether the cached aggregate is from today.
    static var isHourlyAggregateStale: Bool {
        guard let cached = defaults?.string(forKey: DefaultsKeys.hourlyAggregateDate) else { return true }
        return cached != todayString
    }

    private static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
