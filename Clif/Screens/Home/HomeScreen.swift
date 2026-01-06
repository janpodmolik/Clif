import SwiftUI

struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    #if DEBUG
    @State private var windIntensity: CGFloat = 0.5
    @State private var windDirection: CGFloat = 1.0
    @State private var petSkin: Int = 1
    @State private var bendCurve: CGFloat = 2.0
    @State private var useCustomBendCurve: Bool = false
    @State private var swayAmount: CGFloat = 0.0
    #endif

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }

                #if DEBUG
                CliffView(
                    screenHeight: geometry.size.height,
                    windIntensity: windIntensity,
                    windDirection: windDirection,
                    petSkin: petSkin,
                    bendCurve: useCustomBendCurve ? bendCurve : nil,
                    swayAmount: swayAmount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
                #else
                CliffView(screenHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
                #endif

                StatusCardContentView(
                    streakCount: 19,
                    usedTimeText: "32m",
                    dailyLimitText: "2h",
                    progress: 0.27
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)

                #if DEBUG
                // Wind Debug Controls
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Wind Debug")
                            .font(.headline)

                        HStack {
                            Text("Intensity: \(windIntensity, specifier: "%.2f")")
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $windIntensity, in: 0...2)
                        }

                        HStack {
                            Text("Direction")
                            Picker("", selection: $windDirection) {
                                Text("← Left").tag(-1.0 as CGFloat)
                                Text("→ Right").tag(1.0 as CGFloat)
                            }
                            .pickerStyle(.segmented)
                        }

                        HStack {
                            Text("Skin: plant-\(petSkin)")
                            Spacer()
                            Stepper("", value: $petSkin, in: 1...5)
                                .labelsHidden()
                        }

                        Divider()

                        HStack {
                            Text("Sway: \(swayAmount, specifier: "%.1f")")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $swayAmount, in: 0...2)
                        }

                        Toggle("Custom Bend Curve", isOn: $useCustomBendCurve)

                        if useCustomBendCurve {
                            HStack {
                                Text("Bend: \(bendCurve, specifier: "%.1f")")
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $bendCurve, in: 0.5...4.0)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                }
                #endif
            }
        }
    }
}

#Preview {
    HomeScreen()
}
