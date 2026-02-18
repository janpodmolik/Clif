import SwiftUI

@Observable
final class EvolutionTransitionAnimator {
    // MARK: - Read-only State

    /// Whether the transition view should be displayed.
    private(set) var isShowingTransition = false

    /// Whether a transition is in progress (prevents re-triggering).
    private(set) var isTransitioning = false

    /// Unique key to force view recreation for each transition.
    private(set) var transitionKey = UUID()

    /// Asset name for the old (pre-evolution) pet.
    private(set) var oldAssetName = ""

    /// Asset name for the new (post-evolution) pet.
    private(set) var newAssetName = ""

    /// Eyes asset name for the old (pre-evolution) pet.
    private(set) var oldEyesAssetName = ""

    /// Eyes asset name for the new (post-evolution) pet.
    private(set) var newEyesAssetName = ""

    /// Display scale for the old pet phase.
    private(set) var oldScale: CGFloat = 1.0

    /// Display scale for the new pet phase.
    private(set) var newScale: CGFloat = 1.0

    // MARK: - Camera Transform

    /// Camera transform driven by the transition animation.
    /// Written by EvolutionTransitionView via Binding, read by HomeScreen for scaleEffect/offset.
    var cameraTransform: EvolutionCameraTransform = .identity

    // MARK: - Private


    // MARK: - Configuration

    var transitionConfig: EvolutionTransitionConfig {
        var config = EvolutionTransitionConfig.default
        config.duration = 4.0
        config.glowPeakIntensity = 4.0
        return config
    }

    var particleConfig: EvolutionParticleConfig {
        var config = EvolutionParticleConfig.default
        config.particleCount = 160
        return config
    }

    // MARK: - API

    /// Triggers the evolution transition for the given pet.
    /// Snapshots current and next phase assets, then starts the transition.
    func trigger(pet: Pet) {
        guard !isTransitioning else { return }
        guard pet.canEvolve else { return }

        let currentPhase = pet.currentPhase
        let nextPhase = currentPhase + 1
        let windLevel = WindLevel.none

        oldAssetName = pet.evolutionPath?.phase(at: currentPhase)?.bodyAssetName(for: windLevel)
            ?? pet.bodyAssetName(for: windLevel)
        newAssetName = pet.evolutionPath?.phase(at: nextPhase)?.bodyAssetName(for: windLevel)
            ?? pet.bodyAssetName(for: windLevel)
        oldEyesAssetName = pet.evolutionPath?.phase(at: currentPhase)?.eyesAssetName(for: windLevel)
            ?? pet.eyesAssetName(for: windLevel)
        newEyesAssetName = pet.evolutionPath?.phase(at: nextPhase)?.eyesAssetName(for: windLevel)
            ?? pet.eyesAssetName(for: windLevel)
        oldScale = pet.evolutionPath?.phase(at: currentPhase)?.displayScale ?? pet.displayScale
        newScale = pet.evolutionPath?.phase(at: nextPhase)?.displayScale ?? pet.displayScale

        startTransition()
        pet.evolve()
    }

    /// Triggers the evolution transition for applying essence to a blob pet.
    /// Snapshots blob assets as old and phase 1 of the essence path as new.
    func triggerEssenceApplication(pet: Pet, essence: Essence) {
        guard !isTransitioning else { return }
        guard pet.isBlob else { return }

        let windLevel = WindLevel.none
        let path = EvolutionPath.path(for: essence)

        oldAssetName = Blob.shared.bodyAssetName(for: windLevel)
        newAssetName = path.phase(at: 1)?.bodyAssetName(for: windLevel) ?? oldAssetName
        oldEyesAssetName = Blob.shared.eyesAssetName(for: windLevel)
        newEyesAssetName = path.phase(at: 1)?.eyesAssetName(for: windLevel) ?? oldEyesAssetName
        oldScale = Blob.shared.displayScale
        newScale = path.phase(at: 1)?.displayScale ?? oldScale

        startTransition()
        pet.applyEssence(essence)
    }

    /// Called when the transition animation completes.
    func complete() {
        isShowingTransition = false
        isTransitioning = false
        cameraTransform = .identity
    }

    /// Resets all state (e.g. when pet changes).
    func reset() {
        isShowingTransition = false
        isTransitioning = false
        cameraTransform = .identity
        oldAssetName = ""
        newAssetName = ""
        oldEyesAssetName = ""
        newEyesAssetName = ""
        oldScale = 1.0
        newScale = 1.0
    }

    // MARK: - Private

    private func startTransition() {
        transitionKey = UUID()
        isTransitioning = true
        isShowingTransition = true
        SoundManager.shared.play(.evolve)
    }
}
