import Foundation

enum CommittedBreakDuration: Int, CaseIterable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninety = 90
    case onetwenty = 120

    var minutes: Int { rawValue }

    var coins: Int {
        CoinRewards.forBreak(minutes: rawValue)
    }

    static var allMinutes: [Int] {
        allCases.map(\.rawValue)
    }

    init?(minutes: Int) {
        guard let duration = CommittedBreakDuration(rawValue: minutes) else { return nil }
        self = duration
    }
}
