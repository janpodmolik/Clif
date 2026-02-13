import SwiftUI

struct ThemeRadialBackground: View {
    @AppStorage(DefaultsKeys.appearanceMode) private var appearanceMode: AppearanceMode = .automatic
    @AppStorage(DefaultsKeys.selectedDayTheme) private var dayTheme: DayTheme = .morningHaze
    @AppStorage(DefaultsKeys.selectedNightTheme) private var nightTheme: NightTheme = .deepNight
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeColor = resolvedThemeColor

        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    Color.black
                } else {
                    Color(uiColor: .systemGroupedBackground)
                }

                RadialGradient(
                    colors: [
                        themeColor.opacity(colorScheme == .dark ? 0.35 : 0.6),
                        themeColor.opacity(colorScheme == .dark ? 0.12 : 0.2),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.75
                )
            }
        }
        .ignoresSafeArea()
    }

    private var resolvedThemeColor: Color {
        switch appearanceMode {
        case .dark:
            nightTheme.gradient.last ?? .purple
        case .light:
            dayTheme.gradient.first ?? .blue
        case .automatic:
            if SkyGradient.isDaytime() {
                dayTheme.gradient.first ?? .blue
            } else {
                nightTheme.gradient.last ?? .purple
            }
        }
    }
}
