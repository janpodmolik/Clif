import SwiftUI

struct OnboardingWindPresetStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    @Environment(\.onboardingFontScale) private var fontScale

    @State private var selectedPreset: WindPreset = .balanced
    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var showCards = false
    @State private var showInfo = false

    // MARK: - Narrative Text
    private let narrativeLine1 = "How strict should the wind be?"
    private let narrativeLine2 = "Pick what feels realistic. You'll choose again tomorrow."

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showCards {
                presetCards
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            if showCards {
                VStack(spacing: 12) {
                    if showInfo {
                        info
                            .transition(.opacity)
                    }
                    continueButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .overlay {
            if !textCompleted && !skipAnimation {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticType.impactLight.trigger()
                        narrativeBeat += 1
                    }
            }
        }
        .animation(.easeOut(duration: 0.3), value: showCards)
        .animation(.easeOut(duration: 0.3), value: showInfo)
        .onAppear { handleAppear() }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            Group {
                if skipAnimation {
                    Text(narrativeLine1)
                } else {
                    let skipped = narrativeBeat >= 1
                    TypewriterText(
                        text: narrativeLine1,
                        skipRequested: skipped,
                        onCompleted: {
                            Task {
                                if !skipped {
                                    try? await Task.sleep(for: .seconds(0.5))
                                }
                                withAnimation { showSecondLine = true }
                            }
                        }
                    )
                }
            }
            .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))

            Group {
                if skipAnimation {
                    Text(narrativeLine2)
                } else {
                    TypewriterText(
                        text: narrativeLine2,
                        active: showSecondLine,
                        skipRequested: narrativeBeat >= 2,
                        onCompleted: {
                            textCompleted = true
                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                withAnimation { showCards = true }
                                try? await Task.sleep(for: .seconds(0.3))
                                withAnimation { showInfo = true }
                            }
                        }
                    )
                    .opacity(showSecondLine ? 1 : 0)
                }
            }
            .font(AppFont.quicksandOnboarding(.title3, weight: .semiBold, scale: fontScale))
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Preset Cards

    private var presetCards: some View {
        VStack(spacing: 12) {
            ForEach(WindPreset.allCases, id: \.self) { preset in
                PresetCard(
                    preset: preset,
                    isSelected: selectedPreset == preset,
                    onTap: {
                        HapticType.impactLight.trigger()
                        withAnimation(.snappy) {
                            selectedPreset = preset
                        }
                    }
                )
            }
        }
    }

    // MARK: - Info

    private var info: some View {
        Label {
            Text("You can change this at the start of each day.")
        } icon: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .font(AppFont.quicksandOnboarding(.footnote, weight: .medium, scale: fontScale))
        .foregroundStyle(.primary.opacity(0.7))
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            savePreset()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Actions

    private func handleAppear() {
        eyesOverride = "neutral"
        windProgress = 0

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showCards = true
            showInfo = true
        }
    }

    private func savePreset() {
        var settings = SharedDefaults.limitSettings
        settings.defaultWindPresetRaw = selectedPreset.rawValue
        SharedDefaults.limitSettings = settings
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let preset: WindPreset
    let isSelected: Bool
    let onTap: () -> Void

    private var onboardingDescription: String {
        let minutes = Int(preset.minutesToBlowAway)
        switch preset {
        case .gentle:
            return "\(minutes) minutes of scrolling before the wind maxes out. A good place to start."
        case .balanced:
            return "\(minutes) minutes. Enough to notice, not too strict. Most users start here."
        case .intense:
            return "\(minutes) minutes. Less room to scroll, more reason to put it down."
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: preset.iconName)
                    .font(.title3)
                    .foregroundStyle(preset.themeColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(preset.displayName)
                            .font(AppFont.quicksandOnboarding(.body, weight: .semiBold, scale: 1.0))
                            .foregroundStyle(.primary)

                        if preset == .balanced {
                            Text("Recommended")
                                .font(AppFont.quicksandOnboarding(.caption, weight: .semiBold, scale: 1.0))
                                .foregroundStyle(preset.themeColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(preset.themeColor.opacity(0.15), in: Capsule())
                        }
                    }

                    Text(onboardingDescription)
                        .font(AppFont.quicksandOnboarding(.callout, weight: .medium, scale: 1.0))
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(preset.themeColor)
                    .font(.title3)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(16)
            .contentShape(Rectangle())
            .glassSelectableBackground(
                cornerRadius: 16,
                isSelected: isSelected,
                tintColor: preset.themeColor
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, windProgress, eyesOverride, _ in
        OnboardingWindPresetStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride
        )
    }
}
#endif
