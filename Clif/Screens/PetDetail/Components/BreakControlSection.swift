import SwiftUI

/// Break control section with preset info and break toggle button.
/// Shows current wind preset and provides quick access to start/end breaks.
struct BreakControlSection: View {
    let preset: WindPreset

    @Environment(PetManager.self) private var petManager

    @State private var showPresetInfo = false
    @State private var showBreakTypePicker = false
    @State private var showCommittedUnlockConfirmation = false

    private var shieldState: ShieldState { ShieldState.shared }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal)

            HStack(spacing: 12) {
                presetIcon

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(preset.displayName)
                            .font(.subheadline.weight(.semibold))

                        infoButton
                    }

                    Text("Today's settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                breakToggleButton
            }
            .padding()
        }
        .sheet(isPresented: $showPresetInfo) {
            WindPresetComparisonSheet(currentPreset: preset)
        }
        .sheet(isPresented: $showBreakTypePicker) {
            BreakTypePicker(
                onSelectFree: {
                    ShieldManager.shared.turnOn(breakType: .free, durationMinutes: nil)
                },
                onConfirmCommitted: { durationMinutes in
                    ShieldManager.shared.turnOn(breakType: .committed, durationMinutes: durationMinutes)
                }
            )
        }
        .confirmationDialog(
            "Ukončit Committed Break?",
            isPresented: $showCommittedUnlockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Ukončit a ztratit peta", role: .destructive) {
                confirmCommittedUnlock()
            }
            Button("Pokračovat v pauze", role: .cancel) {}
        } message: {
            Text("Ukončení committed breaku předčasně způsobí okamžitou ztrátu tvého peta. Tato akce je nevratná.")
        }
    }

    private var presetIcon: some View {
        Image(systemName: preset.iconName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(preset.themeColor)
            .frame(width: 32, height: 32)
            .background(preset.themeColor.opacity(0.15), in: Circle())
    }

    private var infoButton: some View {
        Button {
            showPresetInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private var breakToggleButton: some View {
        Button {
            handleBreakToggle()
        } label: {
            Image(systemName: shieldState.isActive ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(shieldState.isActive ? .cyan : .primary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(shieldState.isActive ? .cyan.opacity(0.15) : Color(.tertiarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }

    private func handleBreakToggle() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if shieldState.isActive {
            if shieldState.currentBreakType == .committed {
                showCommittedUnlockConfirmation = true
            } else {
                ShieldManager.shared.toggle()
            }
        } else {
            showBreakTypePicker = true
        }
    }

    private func confirmCommittedUnlock() {
        petManager.blowAwayCurrentPet(reason: .breakViolation)
        ShieldManager.shared.toggle(success: false)
    }
}

// MARK: - Preset Comparison Sheet

struct WindPresetComparisonSheet: View {
    let currentPreset: WindPreset

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(WindPreset.allCases, id: \.self) { preset in
                        PresetComparisonCard(
                            preset: preset,
                            isCurrent: preset == currentPreset
                        )
                    }

                    explanationSection
                }
                .padding()
            }
            .navigationTitle("Wind Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var explanationSection: some View {
        Text("Wind rises when you use limited apps and falls when you take breaks. TODO: Maybe more info..")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preset Comparison Card

private struct PresetComparisonCard: View {
    let preset: WindPreset
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: preset.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(preset.themeColor)
                .frame(width: 40, height: 40)
                .background(preset.themeColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.displayName)
                    .font(.headline)

                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("~\(Int(preset.minutesToBlowAway)) min to blow away")
                    .font(.caption.monospacedDigit())

                Text("~\(Int(preset.minutesToRecover)) min to full recover")
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? preset.themeColor.opacity(0.1) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? preset.themeColor.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
}

#if DEBUG
#Preview("Gentle") {
    VStack(spacing: 20) {
        BreakControlSection(preset: .gentle)
            .glassCard()
    }
    .padding()
    .environment(PetManager.mock())
}

#Preview("Balanced") {
    VStack(spacing: 20) {
        BreakControlSection(preset: .balanced)
            .glassCard()
    }
    .padding()
    .environment(PetManager.mock())
}

#Preview("Intense") {
    VStack(spacing: 20) {
        BreakControlSection(preset: .intense)
            .glassCard()
    }
    .padding()
    .environment(PetManager.mock())
}

#Preview("Comparison Sheet") {
    WindPresetComparisonSheet(currentPreset: .balanced)
}
#endif
