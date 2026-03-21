import SwiftUI

struct ThemeRadialBackground: View {
    @AppStorage(DefaultsKeys.appearanceMode) private var appearanceMode: AppearanceMode = .automatic
    @AppStorage(DefaultsKeys.useDynamicSky) private var useDynamicSky = false
    @AppStorage(DefaultsKeys.selectedDayTheme) private var dayTheme: DayTheme = .morningHaze
    @AppStorage(DefaultsKeys.selectedNightTheme) private var nightTheme: NightTheme = .deepNight
    @Environment(\.colorScheme) private var colorScheme

    private var usesDynamicGradient: Bool {
        appearanceMode == .automatic && useDynamicSky
    }

    var body: some View {
        if usesDynamicGradient {
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                gradientContent(
                    themeColor: SkyGradient.layer2Stops.interpolated(amount: SkyGradient.timeOfDay())
                )
            }
        } else {
            gradientContent(themeColor: staticThemeColor)
        }
    }

    @ViewBuilder
    private func gradientContent(themeColor: Color) -> some View {
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

    private var staticThemeColor: Color {
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
