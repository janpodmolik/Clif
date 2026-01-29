import SwiftUI

extension BreakType {
    /// Color for UI display.
    var color: Color {
        switch self {
        case .free: return .green
        case .committed: return .orange
        case .safety: return .red
        }
    }
}
