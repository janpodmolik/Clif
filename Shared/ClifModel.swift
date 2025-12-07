import Foundation

/// Represents the visual phases of the cliff mascot based on screen time usage.
enum ClifPhase: Int, CaseIterable {
    case phase1 = 0
    case phase2 = 10
    case phase3 = 20
    case phase4 = 30
    case phase5 = 40
    case phase6 = 50
    case phase7 = 60
    case phase8 = 70
    case phase9 = 80
    case phase10 = 90
    case fallen = 100
    
    /// Returns the appropriate phase based on current progress percentage.
    static func from(progress: Int) -> ClifPhase {
        // Find the highest phase that is less than or equal to current progress
        return allCases.filter { $0.rawValue <= progress }.max(by: { $0.rawValue < $1.rawValue }) ?? .phase1
    }
    
    var imageName: String {
        return "progress_\(rawValue)"
    }
    
    var message: String {
        switch self {
        case .phase1: return "Journey begins"
        case .phase5: return "Halfway there"
        case .phase9: return "Warning: Approaching the edge!"
        case .fallen: return "You fell off the cliff..."
        default: return "Hold on..."
        }
    }
}
