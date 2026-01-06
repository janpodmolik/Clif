import SwiftUI

struct CliffView: View {
    let screenHeight: CGFloat
    var windIntensity: CGFloat = 0.5
    var windDirection: CGFloat = 1.0
    var petSkin: Int = 1
    var bendCurve: CGFloat? = nil
    var swayAmount: CGFloat = 0.0

    private var cliffHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.15 }
    private var petOffset: CGFloat { -petHeight * 0.65 }

    /// Výchozí bendCurve hodnoty pro každý skin
    private var skinBendCurve: CGFloat {
        if let bendCurve { return bendCurve }
        switch petSkin {
        case 1: return 2.5  // plant-1: kompaktní, standardní ohyb
        case 2: return 2.2  // plant-2: malá stopka, mírně jemnější
        case 3: return 2.0  // plant-3: střední listy
        case 4: return 1.8  // plant-4: větší listy
        case 5: return 1.4  // plant-5: vysoká kytička, nejjemnější ohyb
        default: return 2.0
        }
    }

    var body: some View {
        Image("rock")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: cliffHeight)
            .overlay(alignment: .top) {
                Image("grass")
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .top) {
                        Image("plant-\(petSkin)")
                            .resizable()
                            .scaledToFit()
                            .frame(height: petHeight)
                            .padding(.horizontal, 30)
                            .windEffect(
                                intensity: windIntensity,
                                direction: windDirection,
                                bendCurve: skinBendCurve,
                                swayAmount: swayAmount
                            )
                            .offset(y: petOffset)
                    }
            }
    }
}

#Preview {
    WindDebugView()
}

private struct WindDebugView: View {
    @State private var intensity: CGFloat = 0.5
    @State private var direction: CGFloat = 1.0
    @State private var petSkin: Int = 1
    @State private var bendCurve: CGFloat = 2.0
    @State private var useCustomBendCurve: Bool = false
    @State private var swayAmount: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.blue.opacity(0.3)

                CliffView(
                    screenHeight: geometry.size.height,
                    windIntensity: intensity,
                    windDirection: direction,
                    petSkin: petSkin,
                    bendCurve: useCustomBendCurve ? bendCurve : nil,
                    swayAmount: swayAmount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Debug controls
                VStack {
                    VStack(spacing: 12) {
                        Text("Wind Debug")
                            .font(.headline)

                        HStack {
                            Text("Intensity: \(intensity, specifier: "%.2f")")
                            Slider(value: $intensity, in: 0...2)
                        }

                        HStack {
                            Text("Direction")
                            Picker("", selection: $direction) {
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
                            Slider(value: $swayAmount, in: 0...2)
                        }

                        Toggle("Custom Bend Curve", isOn: $useCustomBendCurve)

                        if useCustomBendCurve {
                            HStack {
                                Text("Bend: \(bendCurve, specifier: "%.1f")")
                                Slider(value: $bendCurve, in: 0.5...4.0)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
