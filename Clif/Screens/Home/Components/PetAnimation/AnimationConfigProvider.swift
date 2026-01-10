import Foundation

/// Provides animation configurations for different evolutions.
/// Lives in Clif target since Shield extensions don't need animation configs.
enum AnimationConfigProvider {

    // MARK: - Idle Config

    static func idleConfig(for evolution: any EvolutionType) -> IdleConfig {
        switch evolution {
        case let plant as PlantEvolution:
            return plantIdleConfig(for: plant)
        case is BlobEvolution:
            return blobIdleConfig
        default:
            return .default
        }
    }

    // MARK: - Tap Config

    static func tapConfig(for evolution: any EvolutionType, type: TapAnimationType) -> TapConfig {
        switch type {
        case .none:
            return .none
        case .wiggle:
            return wiggleConfig(for: evolution)
        case .squeeze:
            return squeezeConfig(for: evolution)
        case .jiggle:
            return jiggleConfig(for: evolution)
        case .bounce:
            return bounceConfig(for: evolution)
        }
    }

    // MARK: - Plant Idle Configs

    private static func plantIdleConfig(for plant: PlantEvolution) -> IdleConfig {
        switch plant {
        case .phase1:
            return IdleConfig(
                enabled: true,
                amplitude: 0.03,
                frequency: 0.4,
                focusStart: 0.33,
                focusEnd: 0.7
            )
        case .phase2:
            return IdleConfig(
                enabled: true,
                amplitude: 0.03,
                frequency: 0.4,
                focusStart: 0.33,
                focusEnd: 0.7
            )
        case .phase3:
            return IdleConfig(
                enabled: true,
                amplitude: 0.03,
                frequency: 0.4,
                focusStart: 0.33,
                focusEnd: 0.7
            )
        case .phase4:
            return IdleConfig(
                enabled: true,
                amplitude: 0.03,
                frequency: 0.4,
                focusStart: 0.33,
                focusEnd: 0.7
            )
        }
    }

    // MARK: - Blob Idle Config

    private static var blobIdleConfig: IdleConfig {
        IdleConfig(
            enabled: true,
            amplitude: 0.03,
            frequency: 0.4,
            focusStart: 0.33,
            focusEnd: 0.7
        )
    }

    // MARK: - Wiggle Tap Configs

    private static func wiggleConfig(for evolution: any EvolutionType) -> TapConfig {
        switch evolution {
        case let plant as PlantEvolution:
            return plantWiggleConfig(for: plant)
        case is BlobEvolution:
            return TapConfig(intensity: 8, decayRate: 8.0, frequency: 40)
        default:
            return .default(for: .wiggle)
        }
    }

    private static func plantWiggleConfig(for plant: PlantEvolution) -> TapConfig {
        switch plant {
        case .phase1: return TapConfig(intensity: 8, decayRate: 8.0, frequency: 40)
        case .phase2: return TapConfig(intensity: 8, decayRate: 8.0, frequency: 40)
        case .phase3: return TapConfig(intensity: 8, decayRate: 8.0, frequency: 40)
        case .phase4: return TapConfig(intensity: 8, decayRate: 8.0, frequency: 40)
        }
    }

    // MARK: - Squeeze Tap Configs

    private static func squeezeConfig(for evolution: any EvolutionType) -> TapConfig {
        switch evolution {
        case let plant as PlantEvolution:
            return plantSqueezeConfig(for: plant)
        case is BlobEvolution:
            return TapConfig(intensity: 0.1, decayRate: 6.0, frequency: 12)
        default:
            return .default(for: .squeeze)
        }
    }

    private static func plantSqueezeConfig(for plant: PlantEvolution) -> TapConfig {
        switch plant {
        case .phase1: return TapConfig(intensity: 0.1, decayRate: 6.0, frequency: 12)
        case .phase2: return TapConfig(intensity: 0.1, decayRate: 6.0, frequency: 12)
        case .phase3: return TapConfig(intensity: 0.1, decayRate: 6.0, frequency: 12)
        case .phase4: return TapConfig(intensity: 0.1, decayRate: 6.0, frequency: 12)
        }
    }

    // MARK: - Jiggle Tap Configs

    private static func jiggleConfig(for evolution: any EvolutionType) -> TapConfig {
        switch evolution {
        case let plant as PlantEvolution:
            return plantJiggleConfig(for: plant)
        case is BlobEvolution:
            return TapConfig(intensity: 15, decayRate: 5.0, frequency: 15)
        default:
            return .default(for: .jiggle)
        }
    }

    private static func plantJiggleConfig(for plant: PlantEvolution) -> TapConfig {
        switch plant {
        case .phase1: return TapConfig(intensity: 15, decayRate: 5.0, frequency: 15)
        case .phase2: return TapConfig(intensity: 15, decayRate: 5.0, frequency: 15)
        case .phase3: return TapConfig(intensity: 15, decayRate: 5.0, frequency: 15)
        case .phase4: return TapConfig(intensity: 15, decayRate: 5.0, frequency: 15)
        }
    }

    // MARK: - Jump Tap Configs

    private static func bounceConfig(for evolution: any EvolutionType) -> TapConfig {
        switch evolution {
        case let plant as PlantEvolution:
            return plantBounceConfig(for: plant)
        case is BlobEvolution:
            return TapConfig(intensity: 0.15, decayRate: 4.0, frequency: 8)
        default:
            return .default(for: .bounce)
        }
    }

    private static func plantBounceConfig(for plant: PlantEvolution) -> TapConfig {
        switch plant {
        case .phase1: return TapConfig(intensity: 0.15, decayRate: 4.0, frequency: 8)
        case .phase2: return TapConfig(intensity: 0.15, decayRate: 4.0, frequency: 8)
        case .phase3: return TapConfig(intensity: 0.15, decayRate: 4.0, frequency: 8)
        case .phase4: return TapConfig(intensity: 0.15, decayRate: 4.0, frequency: 8)
        }
    }
}
