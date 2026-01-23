import FamilyControls
import ManagedSettings
import SwiftUI

/// A section displaying wind preset configuration and limited sources.
/// Designed to be placed below the pet header content within the same card.
/// This is a read-only informational section.
struct WindPresetInfoSection: View {
    let preset: WindPreset
    let limitedSources: [LimitedSource]

    private var applicationTokens: Set<ApplicationToken> {
        Set(limitedSources.compactMap {
            if case .app(let source) = $0 { return source.applicationToken }
            return nil
        })
    }

    private var categoryTokens: Set<ActivityCategoryToken> {
        Set(limitedSources.compactMap {
            if case .category(let source) = $0 { return source.categoryToken }
            return nil
        })
    }

    private var webDomainTokens: Set<WebDomainToken> {
        Set(limitedSources.compactMap {
            if case .website(let source) = $0 { return source.webDomainToken }
            return nil
        })
    }

    private var hasValidTokens: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal)

            HStack(spacing: 12) {
                modeIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))

                    Text("\(Int(preset.minutesToBlowAway)) min to blow away")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if hasValidTokens {
                    LimitedSourcesPreview(
                        applicationTokens: applicationTokens,
                        categoryTokens: categoryTokens,
                        webDomainTokens: webDomainTokens
                    )
                } else {
                    sourcesCountBadge
                }
            }
            .padding()
        }
    }

    private var modeIcon: some View {
        Image(systemName: preset.iconName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(preset.themeColor)
            .frame(width: 32, height: 32)
            .background(preset.themeColor.opacity(0.15), in: Circle())
    }

    /// Fallback when no valid tokens are available (e.g. archived pets without tokens)
    private var sourcesCountBadge: some View {
        let count = limitedSources.count
        return HStack(spacing: 4) {
            Image(systemName: "app.badge.fill")
                .font(.caption)
            Text("\(count)")
                .fontWeight(.medium)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1), in: Capsule())
    }
}

#if DEBUG
#Preview("Balanced") {
    VStack(spacing: 20) {
        WindPresetInfoSection(
            preset: .balanced,
            limitedSources: LimitedSource.mockList()
        )
        .glassCard()
    }
    .padding()
}

#Preview("Intense") {
    VStack(spacing: 20) {
        WindPresetInfoSection(
            preset: .intense,
            limitedSources: LimitedSource.mockList()
        )
        .glassCard()
    }
    .padding()
}
#endif
