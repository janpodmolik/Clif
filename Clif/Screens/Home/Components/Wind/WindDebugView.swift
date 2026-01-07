#if DEBUG
import SwiftUI

/// Debug view for testing and configuring wind effect parameters.
struct WindDebugView: View {
    @State private var selectedEvolutionType: EvolutionTypeOption = .plant
    @State private var plantPhase: Int = 1
    @State private var windLevel: WindLevel = .medium
    @State private var direction: CGFloat = 1.0
    @State private var showControls: Bool = true

    // Custom override mode
    @State private var useCustomConfig: Bool = false
    @State private var customIntensity: CGFloat = 0.5
    @State private var customBendCurve: CGFloat = 2.0
    @State private var customSwayAmount: CGFloat = 0.3
    @State private var customRotationAmount: CGFloat = 0.5

    enum EvolutionTypeOption: String, CaseIterable {
        case blob = "Blob"
        case plant = "Plant"
    }

    private var customConfig: WindConfig? {
        guard useCustomConfig else { return nil }
        return WindConfig(
            intensity: customIntensity,
            bendCurve: customBendCurve,
            swayAmount: customSwayAmount,
            rotationAmount: customRotationAmount
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.blue.opacity(0.3)

                // Cliff with pet - render appropriate evolution type
                Group {
                    switch selectedEvolutionType {
                    case .blob:
                        CliffView(
                            screenHeight: geometry.size.height,
                            evolution: BlobEvolution.blob,
                            windLevel: windLevel,
                            debugWindConfig: customConfig,
                            windDirection: direction
                        )
                    case .plant:
                        CliffView(
                            screenHeight: geometry.size.height,
                            evolution: PlantEvolution(rawValue: plantPhase) ?? .phase1,
                            windLevel: windLevel,
                            debugWindConfig: customConfig,
                            windDirection: direction
                        )
                    }
                }
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
        // Evolution type selector
        Picker("Evolution", selection: $selectedEvolutionType) {
            ForEach(EvolutionTypeOption.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)

        // Phase selector (only for plant)
        if selectedEvolutionType == .plant {
            HStack {
                Text("Phase: \(plantPhase)")
                Spacer()
                Stepper("", value: $plantPhase, in: 1...4)
                    .labelsHidden()
            }
        }

        Divider()

        // Wind level selector
        VStack(alignment: .leading, spacing: 4) {
            Text("Wind Level")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Wind Level", selection: $windLevel) {
                ForEach(WindLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
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

        Divider()

        // Custom config toggle
        Toggle("Custom Override", isOn: $useCustomConfig)

        if useCustomConfig {
            customConfigControls
        }
    }

    @ViewBuilder
    private var customConfigControls: some View {
        HStack {
            Text("Intensity: \(customIntensity, specifier: "%.2f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customIntensity, in: 0...2)
        }

        HStack {
            Text("Bend: \(customBendCurve, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customBendCurve, in: 0.5...4.0)
        }

        HStack {
            Text("Sway: \(customSwayAmount, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customSwayAmount, in: 0...2)
        }

        HStack {
            Text("Rotation: \(customRotationAmount, specifier: "%.1f")")
                .frame(width: 120, alignment: .leading)
            Slider(value: $customRotationAmount, in: 0...2)
        }
    }
}

#Preview {
    WindDebugView()
}
#endif
