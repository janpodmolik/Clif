import SwiftUI

/// A section displaying today's wind preset configuration.
/// Shows rise/fall rates and provides access to preset comparison.
struct WindPresetInfoSection: View {
    let preset: WindPreset

    @State private var showPresetInfo = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal)

            HStack(spacing: 12) {
                presetIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))

                    Text("Today's settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                infoButton
            }
            .padding()
        }
        .sheet(isPresented: $showPresetInfo) {
            WindPresetComparisonSheet(currentPreset: preset)
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
                .font(.system(size: 18))
                .foregroundStyle(.primary)
        }
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
        WindPresetInfoSection(preset: .gentle)
            .glassCard()
    }
    .padding()
}

#Preview("Balanced") {
    VStack(spacing: 20) {
        WindPresetInfoSection(preset: .balanced)
            .glassCard()
    }
    .padding()
}

#Preview("Intense") {
    VStack(spacing: 20) {
        WindPresetInfoSection(preset: .intense)
            .glassCard()
    }
    .padding()
}

#Preview("Comparison Sheet") {
    WindPresetComparisonSheet(currentPreset: .balanced)
}
#endif
