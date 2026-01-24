import SwiftUI

struct MorningPresetPicker: View {
    @Environment(PetManager.self) private var petManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset: WindPreset = .balanced

    private var currentPet: Pet? { petManager.currentPet }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange.gradient)

                    Text("Dobré ráno!")
                        .font(.title.bold())

                    Text("Jak náročný den chceš mít?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Preset options
                VStack(spacing: 12) {
                    ForEach(WindPreset.allCases, id: \.self) { preset in
                        PresetOptionRow(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            withAnimation(.snappy) {
                                selectedPreset = preset
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Confirm button
                Button {
                    confirmSelection()
                } label: {
                    Text("Začít den")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPreset.themeColor, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-select current pet's preset if available
            if let pet = currentPet {
                selectedPreset = pet.preset
            }
        }
    }

    private func confirmSelection() {
        if let pet = currentPet {
            ScreenTimeManager.shared.applyMorningPreset(selectedPreset, for: pet)
        }
        dismiss()
    }
}

private struct PresetOptionRow: View {
    let preset: WindPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: preset.iconName)
                    .font(.title2)
                    .foregroundStyle(preset.themeColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(presetDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(preset.themeColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? preset.themeColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? preset.themeColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var presetDescription: String {
        switch preset {
        case .gentle:
            return "\(Int(preset.minutesToBlowAway)) min do limitu • Klidný den"
        case .balanced:
            return "\(Int(preset.minutesToBlowAway)) min do limitu • Vyvážený den"
        case .intense:
            return "\(Int(preset.minutesToBlowAway)) min do limitu • Výzva"
        }
    }
}

#Preview {
    MorningPresetPicker()
        .environment(PetManager.mock())
}
