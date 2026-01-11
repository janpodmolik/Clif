import FamilyControls
import ManagedSettings
import SwiftUI

struct BlockedAppsPreview: View {
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>

    private var displayAppTokens: [ApplicationToken] {
        Array(applicationTokens.prefix(4))
    }

    private var displayCategoryTokens: [ActivityCategoryToken] {
        Array(categoryTokens.prefix(max(0, 4 - displayAppTokens.count)))
    }

    private var remainingCount: Int {
        let shown = displayAppTokens.count + displayCategoryTokens.count
        let total = applicationTokens.count + categoryTokens.count
        return total - shown
    }

    var body: some View {
        HStack(spacing: -6) {
            ForEach(displayAppTokens.indices, id: \.self) { index in
                Label(displayAppTokens[index])
                    .labelStyle(.iconOnly)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            ForEach(displayCategoryTokens.indices, id: \.self) { index in
                Label(displayCategoryTokens[index])
                    .labelStyle(.iconOnly)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if remainingCount > 0 {
                Text("+\(remainingCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
