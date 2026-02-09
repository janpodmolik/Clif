import SwiftUI

struct ShieldSettingsScreen: View {
    @State private var limitSettings = SharedDefaults.limitSettings
    @State private var showPresetInfo = false

    private var defaultPresetBinding: Binding<WindPreset> {
        Binding(
            get: { WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced },
            set: { limitSettings.defaultWindPresetRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            // MARK: - Denní shield
            Section(header: dailyShieldHeader, footer: dailyShieldFooter) {
                Toggle("Denní shield", isOn: $limitSettings.dayStartShieldEnabled)
                    .tint(.blue)

                if !limitSettings.dayStartShieldEnabled {
                    Picker(selection: defaultPresetBinding) {
                        ForEach(WindPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    } label: {
                        Text("Výchozí preset")
                    }
                }
            }

            // MARK: - Safety Shield
            Section(header: sectionHeader("Safety Shield"), footer: safetyFooter) {
                Picker(selection: $limitSettings.safetyShieldActivationThreshold) {
                    Text("80 %").tag(80)
                    Text("100 %").tag(100)
                } label: {
                    Label("Aktivace při", systemImage: "shield.fill")
                }

                Picker(selection: $limitSettings.safetyUnlockThreshold) {
                    Text("0 %").tag(0)
                    Text("50 %").tag(50)
                    Text("80 %").tag(80)
                } label: {
                    Label("Bezpečný unlock pod", systemImage: "lock.open.fill")
                }
            }

            // MARK: - Po breaku
            Section(header: sectionHeader("Po breaku")) {
                NotificationToggleRow(
                    title: "Auto-lock po committed breaku",
                    description: "Automaticky zapne free break po dokončení committed breaku.",
                    isOn: $limitSettings.autoLockAfterCommittedBreak
                )
            }
        }
        .navigationTitle("Shield")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: limitSettings) { _, newValue in
            SharedDefaults.limitSettings = newValue
        }
        .sheet(isPresented: $showPresetInfo) {
            WindPresetComparisonSheet(
                currentPreset: WindPreset(rawValue: limitSettings.defaultWindPresetRaw) ?? .balanced
            )
        }
    }

    // MARK: - Section Headers & Footers

    private var dailyShieldHeader: some View {
        HStack {
            Text("Denní shield")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .textCase(nil)

            Spacer()

            Button {
                showPresetInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var dailyShieldFooter: some View {
        Group {
            if limitSettings.dayStartShieldEnabled {
                Text("Při zapnutí se každé ráno zobrazí výběr presetu. Aplikace zůstanou zamčené, dokud nevybereš.")
            } else {
                Text("Bez denního shieldu se automaticky použije výchozí preset. Aplikace nebudou ráno zamčené.")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .textCase(nil)
    }

    private var safetyFooter: some View {
        Text("Safety shield se automaticky aktivuje při dosažení nastaveného procenta větru. Odemknout bezpečně lze až vítr klesne pod zvolený práh.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        ShieldSettingsScreen()
    }
}
