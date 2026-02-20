import SwiftUI

/// Simplified debug view for internal TestFlight testers.
/// Provides essential controls: evolution, wind override, and wind reset.
struct TesterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PetManager.self) private var petManager

    @State private var windOverrideEnabled = TesterConfig.isEnabled
    @State private var blowAwayMinutes = TesterConfig.minutesToBlowAway
    @State private var recoverMinutes = TesterConfig.minutesToRecover
    @State private var refreshTick = 0

    var body: some View {
        NavigationStack {
            List {
                if let pet = petManager.currentPet {
                    evolutionSection(pet)
                    windOverrideSection
                    windActionsSection(pet)
                } else {
                    Section {
                        Text("No active pet")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Tester Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Evolution

    @ViewBuilder
    private func evolutionSection(_ pet: Pet) -> some View {
        Section {
            LabeledContent("Phase", value: "\(pet.currentPhase) / \(pet.evolutionHistory.maxPhase)")
            LabeledContent("Days alive", value: "\(pet.daysSinceCreation)")
            LabeledContent("Essence", value: pet.essence?.rawValue ?? "none (blob)")

            if pet.evolutionHistory.hasProgressedToday {
                LabeledContent("Progressed today", value: "Yes")
            }

            if let unlockDate = pet.evolutionHistory.nextEvolutionUnlockDate {
                LabeledContent("Next unlock") {
                    Text(unlockDate, style: .relative)
                        .foregroundStyle(pet.evolutionHistory.isUnlockTimePassed ? .green : .secondary)
                }
            }
        } header: {
            Text("Evolution")
        } footer: {
            Text("Use buttons below to speed up evolution for testing.")
        }

        Section {
            Button("+1 Day (bump age)") {
                pet.debugBumpDay()
                petManager.savePet()
            }

            if !pet.isBlob {
                Button("Unlock Evolution Now") {
                    pet.debugSetUnlockIn(minutes: 0)
                    petManager.savePet()
                    ScheduledNotificationManager.refresh(
                        isEvolutionAvailable: true,
                        hasPet: true,
                        nextEvolutionUnlockDate: pet.evolutionHistory.nextEvolutionUnlockDate
                    )
                }

                Button("Evolve to Next Phase") {
                    pet.debugUnlockEvolution()
                    pet.evolve()
                    petManager.savePet()
                }
            }

            Button("Reset to Blob", role: .destructive) {
                pet.debugResetToBlob()
                petManager.savePet()
            }
        } header: {
            Text("Evolution Actions")
        }
    }

    // MARK: - Wind Override

    private var windOverrideSection: some View {
        Section {
            Toggle("Fast Wind Preset", isOn: $windOverrideEnabled)
                .onChange(of: windOverrideEnabled) { _, newValue in
                    TesterConfig.isEnabled = newValue
                    if newValue {
                        restartMonitoringIfNeeded()
                    } else {
                        restartMonitoringWithOriginalPreset()
                    }
                }

            if windOverrideEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Blow away: \(String(format: "%.0f", blowAwayMinutes)) min")
                        .font(.subheadline)
                    Slider(value: $blowAwayMinutes, in: 1...10, step: 1)
                        .onChange(of: blowAwayMinutes) { _, newValue in
                            TesterConfig.minutesToBlowAway = newValue
                            restartMonitoringIfNeeded()
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery: \(String(format: "%.0f", recoverMinutes)) min")
                        .font(.subheadline)
                    Slider(value: $recoverMinutes, in: 1...10, step: 1)
                        .onChange(of: recoverMinutes) { _, newValue in
                            TesterConfig.minutesToRecover = newValue
                            SharedDefaults.monitoredFallRate = TesterConfig.fallRate / 60.0
                        }
                }
            }
        } header: {
            Text("Wind Speed")
        } footer: {
            if windOverrideEnabled {
                Text("Overrides daily preset. Rise: \(String(format: "%.0f", TesterConfig.riseRate)) pts/min, Fall: \(String(format: "%.0f", TesterConfig.fallRate)) pts/min")
            } else {
                Text("Enable to use accelerated wind timing for testing.")
            }
        }
    }

    // MARK: - Wind Actions

    private func windActionsSection(_ pet: Pet) -> some View {
        Section {
            let _ = refreshTick
            LabeledContent("Wind") {
                Text("\(String(format: "%.0f", SharedDefaults.monitoredWindPoints))%")
                    .foregroundStyle(SharedDefaults.monitoredWindPoints >= 80 ? .red : .primary)
            }

            Button("Reset Wind to 0%") {
                SharedDefaults.monitoredWindPoints = 0
                SharedDefaults.monitoredLastThresholdSeconds = 0
                SharedDefaults.totalBreakReduction = 0
                SharedDefaults.cumulativeBaseline = 0
                // Restart monitoring to reset DeviceActivity's internal counter
                ScreenTimeManager.shared.restartMonitoring()
                refreshTick += 1
            }
        } header: {
            Text("Wind State")
        }
    }

    // MARK: - Helpers

    private func restartMonitoringIfNeeded() {
        guard let pet = petManager.currentPet else { return }

        let limitSeconds = Int(TesterConfig.minutesToBlowAway * 60)
        let fallRatePerSecond = TesterConfig.fallRate / 60.0
        SharedDefaults.monitoredFallRate = fallRatePerSecond

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            petName: pet.name,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }

    /// Restarts monitoring with the pet's original preset values (when tester override is turned off).
    private func restartMonitoringWithOriginalPreset() {
        guard let pet = petManager.currentPet else { return }

        let preset = pet.preset
        let limitSeconds = Int(preset.minutesToBlowAway * 60)
        let fallRatePerSecond = preset.fallRate / 60.0
        SharedDefaults.monitoredFallRate = fallRatePerSecond

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            petName: pet.name,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }
}
