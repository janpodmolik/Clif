import SwiftUI

/// Selects the appropriate sky background based on appearance mode and theme settings.
struct HomeBackgroundView: View {
    @AppStorage(DefaultsKeys.appearanceMode) private var appearanceMode: AppearanceMode = .automatic
    @AppStorage(DefaultsKeys.selectedDayTheme) private var dayTheme: DayTheme = .morningHaze
    @AppStorage(DefaultsKeys.selectedNightTheme) private var nightTheme: NightTheme = .deepNight

    var debugTimeOverride: Double? = nil

    var body: some View {
        #if DEBUG
        if let time = debugTimeOverride {
            AutomaticBackgroundView(timeOverride: time)
        } else {
            defaultBackground
        }
        #else
        defaultBackground
        #endif
    }

    @ViewBuilder
    private var defaultBackground: some View {
        switch appearanceMode {
        case .automatic:
            AutomaticBackgroundView()
        case .light:
            DayBackgroundView(theme: dayTheme)
        case .dark:
            NightBackgroundView(theme: nightTheme)
        }
    }
}
