import Observation
import TelemetryDeck

@Observable
final class AnalyticsManager {

    static let appID = "2C9A23E9-E93E-46A4-BBCF-909AB089DF04"

    func initialize() {
        let config = TelemetryDeck.Config(appID: Self.appID)
        TelemetryDeck.initialize(config: config)
    }

    func send(_ event: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(event, parameters: parameters)
    }
}
