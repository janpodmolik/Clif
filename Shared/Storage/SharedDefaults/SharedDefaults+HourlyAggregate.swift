import Foundation

extension SharedDefaults {

    /// Supported daysLimit values — only these get cached (max 4 keys).
    static let supportedDaysLimits: [Int?] = [7, 14, 30, nil]

    /// Cached hourly usage aggregate (all-time). Nil if not yet computed.
    static var hourlyAggregate: HourlyAggregate? {
        get { hourlyAggregate(daysLimit: nil) }
        set { setHourlyAggregate(newValue, daysLimit: nil) }
    }

    /// Whether the cached all-time aggregate is stale.
    static var isHourlyAggregateStale: Bool {
        isHourlyAggregateStale(daysLimit: nil)
    }

    // MARK: - Parameterized by daysLimit

    static func hourlyAggregate(daysLimit: Int?) -> HourlyAggregate? {
        let key = cacheKey(daysLimit: daysLimit)
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HourlyAggregate.self, from: data)
    }

    static func setHourlyAggregate(_ aggregate: HourlyAggregate?, daysLimit: Int?) {
        guard supportedDaysLimits.contains(where: { $0 == daysLimit }) else { return }
        let key = cacheKey(daysLimit: daysLimit)
        let dateKey = key + "_date"
        if let aggregate, let data = try? JSONEncoder().encode(aggregate) {
            defaults?.set(data, forKey: key)
            defaults?.set(todayString, forKey: dateKey)
        } else {
            defaults?.removeObject(forKey: key)
            defaults?.removeObject(forKey: dateKey)
        }
    }

    static func isHourlyAggregateStale(daysLimit: Int?) -> Bool {
        let dateKey = cacheKey(daysLimit: daysLimit) + "_date"
        guard let cached = defaults?.string(forKey: dateKey) else { return true }
        return cached != todayString
    }

    // MARK: - Private

    private static func cacheKey(daysLimit: Int?) -> String {
        let suffix = daysLimit.map { String($0) } ?? "all"
        return "\(DefaultsKeys.hourlyAggregate)_\(suffix)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static var todayString: String {
        dateFormatter.string(from: Date())
    }
}
