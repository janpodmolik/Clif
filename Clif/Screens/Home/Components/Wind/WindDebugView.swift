#if DEBUG
import SwiftUI

/// Debug view for testing and configuring wind effect parameters.
///
/// This view provides interactive controls to adjust wind effect settings
/// and visualize how different skins respond to wind animation.
///
/// Future use: Configure wind intensity levels per skin for production.
struct WindDebugView: View {
    @State private var intensity: CGFloat = 0.5
    @State private var direction: CGFloat = 1.0
    @State private var petSkin: Int = 1
    @State private var bendCurve: CGFloat = 2.0
    @State private var useCustomBendCurve: Bool = false
    @State private var swayAmount: CGFloat = 0.0
    @State private var rotationAmount: CGFloat = 0.5
    @State private var showControls: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.blue.opacity(0.3)

                // Cliff with pet
                CliffView(
                    screenHeight: geometry.size.height,
                    windIntensity: intensity,
                    windDirection: direction,
                    petSkin: petSkin,
                    bendCurve: useCustomBendCurve ? bendCurve : nil,
                    swayAmount: swayAmount,
                    rotationAmount: rotationAmount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Debug controls panel
                debugControlsPanel
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Debug Controls

    private var debugControlsPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Header with collapse toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                } label: {
                    HStack {
                        Text("Wind Debug")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showControls ? "chevron.down" : "chevron.up")
                    }
                }
                .buttonStyle(.plain)

                if showControls {
                    controlsContent
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
    }

    @ViewBuilder
    private var controlsContent: some View {
        // Wind intensity
        HStack {
            Text("Intensity: \(intensity, specifier: "%.2f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $intensity, in: 0...2)
        }

        // Wind direction
        HStack {
            Text("Direction")
            Picker("", selection: $direction) {
                Text("← Left").tag(-1.0 as CGFloat)
                Text("→ Right").tag(1.0 as CGFloat)
            }
            .pickerStyle(.segmented)
        }

        // Skin selector
        HStack {
            Text("Skin: plant-\(petSkin)")
            Spacer()
            Stepper("", value: $petSkin, in: 1...5)
                .labelsHidden()
        }

        Divider()

        // Sway amount
        HStack {
            Text("Sway: \(swayAmount, specifier: "%.1f")")
                .frame(width: 100, alignment: .leading)
            Slider(value: $swayAmount, in: 0...2)
        }

        // Rotation amount
        HStack {
            Text("Rotation: \(rotationAmount, specifier: "%.1f")")
                .frame(width: 100, alignment: .leading)
            Slider(value: $rotationAmount, in: 0...2)
        }

        // Custom bend curve toggle
        Toggle("Custom Bend Curve", isOn: $useCustomBendCurve)

        if useCustomBendCurve {
            HStack {
                Text("Bend: \(bendCurve, specifier: "%.1f")")
                    .frame(width: 100, alignment: .leading)
                Slider(value: $bendCurve, in: 0.5...4.0)
            }
        }
    }
}

#Preview {
    WindDebugView()
}
#endif
