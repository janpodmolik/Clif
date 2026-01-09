import Foundation

/// Configuration for evolution transition animation.
struct EvolutionTransitionConfig: Equatable {
    /// Total animation duration in seconds.
    var duration: TimeInterval

    /// Glow color RGB components (0-1).
    var glowColorR: CGFloat
    var glowColorG: CGFloat
    var glowColorB: CGFloat

    /// Peak glow intensity multiplier.
    var glowPeakIntensity: CGFloat

    /// Flash duration as fraction of total duration.
    var flashDuration: CGFloat

    var glowColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        (glowColorR, glowColorG, glowColorB)
    }

    /// Progress point (0-1) when flash begins in the shader.
    static let flashStart: CGFloat = 0.55

    /// Calculates when new image should start appearing (middle of flash).
    func assetSwapPoint() -> CGFloat {
        // flashDuration is in seconds, normalize to 0-1 range
        let normalizedFlashDuration = flashDuration / duration
        return Self.flashStart + normalizedFlashDuration * 0.5
    }

    /// Calculates when old image should be hidden (end of flash).
    /// This ensures old image is never visible after the shader's Phase 3 begins.
    func oldImageHidePoint() -> CGFloat {
        // flashDuration is in seconds, normalize to 0-1 range
        // Hide slightly BEFORE shader's Phase 3 to ensure no glitch
        // Shader's flashEnd = 0.55 + normalizedFlashDuration
        let normalizedFlashDuration = flashDuration / duration
        // Subtract small buffer to hide old image just before flash ends
        return Self.flashStart + normalizedFlashDuration - 0.02
    }

    /// Default duration for the transition.
    static let defaultDuration: TimeInterval = 2.0

    static let `default` = EvolutionTransitionConfig(
        duration: defaultDuration,
        glowColorR: 1,
        glowColorG: 0.9,
        glowColorB: 0.6,
        glowPeakIntensity: 2.5,
        flashDuration: 0.2
    )
}

// MARK: - Particle Configuration

/// Configuration for evolution particle effects.
struct EvolutionParticleConfig: Equatable {
    /// Type of particle effect.
    var particleType: EvolutionParticleType

    /// Whether particles are enabled.
    var enabled: Bool

    /// Number of particles (rich/dense effect).
    var particleCount: Int

    /// Base particle size range.
    var minSize: CGFloat
    var maxSize: CGFloat

    /// Particle color RGB (warm silver/white to match glow).
    var colorR: CGFloat
    var colorG: CGFloat
    var colorB: CGFloat

    /// Progress point when particles start appearing.
    var startProgress: CGFloat

    /// Progress point when particles reach peak intensity.
    var peakProgress: CGFloat

    /// Progress point when particles finish fading out.
    var endProgress: CGFloat

    static let `default` = EvolutionParticleConfig(
        particleType: .radialExplosion,
        enabled: true,
        particleCount: 80,
        minSize: 2,
        maxSize: 6,
        colorR: 1.0,
        colorG: 0.95,
        colorB: 0.8,
        startProgress: 0.50,
        peakProgress: 0.60,
        endProgress: 1.0
    )

    static let disabled = EvolutionParticleConfig(
        particleType: .radialExplosion,
        enabled: false,
        particleCount: 0,
        minSize: 0,
        maxSize: 0,
        colorR: 0,
        colorG: 0,
        colorB: 0,
        startProgress: 0,
        peakProgress: 0,
        endProgress: 0
    )
}
