#if DEBUG
import SwiftUI

struct HomeDebugOverlay: View {
    @Environment(PetManager.self) private var petManager
    @Environment(CoinsRewardAnimator.self) private var coinsAnimator

    @Binding var debugBumpState: DebugBumpState
    @Binding var debugTimeOverride: Double?
    @Binding var refreshTick: Int
    let hasPet: Bool

    var body: some View {
        if hasPet {
            VStack(spacing: 8) {
                timeSlider

                HStack(spacing: 8) {
                    bumpToggle
                    coinsButton
                    mockPetButton
                    resetWindButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        } else {
            VStack(spacing: 8) {
                timeSlider
                mockPetButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Components

    private var bumpToggle: some View {
        Menu {
            ForEach(DebugBumpState.allCases, id: \.self) { state in
                Button {
                    debugBumpState = state
                } label: {
                    HStack {
                        Text(state.rawValue)
                        if debugBumpState == state {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            debugCapsule("ladybug.fill", debugBumpState.rawValue)
        }
    }

    private var coinsButton: some View {
        Button {
            coinsAnimator.showReward(5)
        } label: {
            debugCapsule("u.circle.fill", "+5")
        }
    }

    private var mockPetButton: some View {
        Menu {
            Button("Plant P3") { petManager.debugReplacePet(phase: 3, essence: .plant) }
            Button("Plant P4 (fully evolved)") { petManager.debugReplacePet(phase: 4, essence: .plant) }
            Button("Blob") { petManager.debugReplacePet(phase: 0, essence: nil) }
        } label: {
            debugCapsule("leaf.fill", "Mock")
        }
    }

    private var resetWindButton: some View {
        Button {
            SharedDefaults.monitoredWindPoints = 0
            refreshTick += 1
        } label: {
            debugCapsule("wind", "Wind 0")
        }
    }

    private var timeSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Text(debugTimeOverride != nil ? timeLabel : "Time: auto")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Spacer()
                Button(debugTimeOverride != nil ? "Reset" : "Override") {
                    if debugTimeOverride != nil {
                        debugTimeOverride = nil
                    } else {
                        debugTimeOverride = SkyGradient.timeOfDay()
                    }
                }
                .font(.system(size: 11, weight: .medium))
            }

            if debugTimeOverride != nil {
                Slider(
                    value: Binding(
                        get: { debugTimeOverride ?? 0 },
                        set: { debugTimeOverride = $0 }
                    ),
                    in: 0...1
                )
                .tint(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var timeLabel: String {
        guard let time = debugTimeOverride else { return "" }
        let totalSeconds = time * 24 * 60 * 60
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return String(format: "Time: %02d:%02d", hours, minutes)
    }

    private func debugCapsule(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
#endif
