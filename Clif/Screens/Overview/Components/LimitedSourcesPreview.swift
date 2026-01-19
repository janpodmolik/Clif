import FamilyControls
import ManagedSettings
import SwiftUI

struct LimitedSourcesPreview: View {
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>
    var webDomainTokens: Set<WebDomainToken> = []

    private let maxAppIcons = 3
    private let iconSize: CGFloat = 28

    private var displayAppTokens: [ApplicationToken] {
        Array(applicationTokens.prefix(maxAppIcons))
    }

    private var remainingAppCount: Int {
        max(0, applicationTokens.count - maxAppIcons)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Categories: grid icon + count
            if !categoryTokens.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("\(categoryTokens.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Apps: max 3 icons with overlap + remaining count
            if !applicationTokens.isEmpty {
                HStack(spacing: -6) {
                    ForEach(displayAppTokens.indices, id: \.self) { index in
                        Label(displayAppTokens[index])
                            .labelStyle(.iconOnly)
                            .frame(width: iconSize, height: iconSize)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    if remainingAppCount > 0 {
                        Text("+\(remainingAppCount)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: iconSize, height: iconSize)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            // Websites: globe icon + count
            if !webDomainTokens.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("\(webDomainTokens.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
