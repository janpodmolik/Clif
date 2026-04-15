import Observation

@Observable
final class ScreenshotMode {
    static let shared = ScreenshotMode()
    #if DEBUG
    var isActive = false
    #else
    let isActive = false
    #endif
    private init() {}
}
