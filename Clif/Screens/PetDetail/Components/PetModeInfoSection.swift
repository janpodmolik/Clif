import FamilyControls
import ManagedSettings
import SwiftUI

/// A section displaying pet mode configuration.
/// Designed to be placed below the pet header content within the same card.
/// This is a read-only informational section.
struct PetModeInfoSection: View {
    let modeInfo: PetModeInfo

    private var sources: [LimitedSource] {
        modeInfo.limitedSources
    }

    private var applicationTokens: Set<ApplicationToken> {
        Set(sources.compactMap {
            if case .app(let source) = $0 { return source.applicationToken }
            return nil
        })
    }

    private var categoryTokens: Set<ActivityCategoryToken> {
        Set(sources.compactMap {
            if case .category(let source) = $0 { return source.categoryToken }
            return nil
        })
    }

    private var webDomainTokens: Set<WebDomainToken> {
        Set(sources.compactMap {
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
                    Text(modeInfo.modeName)
                        .font(.subheadline.weight(.semibold))

                    modeDetailText
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
        Image(systemName: modeInfo.modeIcon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(modeInfo.modeColor)
            .frame(width: 32, height: 32)
            .background(modeInfo.modeColor.opacity(0.15), in: Circle())
    }

    @ViewBuilder
    private var modeDetailText: some View {
        switch modeInfo {
        case .daily(let info):
            Text("Limit: \(info.formattedLimit) / day")

        case .dynamic(let info):
            Text(info.config.displayName)
        }
    }

    /// Fallback when no valid tokens are available (e.g. archived pets without tokens)
    private var sourcesCountBadge: some View {
        let count = sources.count
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
#Preview("Daily Mode") {
    VStack(spacing: 20) {
        PetModeInfoSection(
            modeInfo: .daily(.init(
                dailyLimitMinutes: 90,
                limitedSources: LimitedSource.mockList()
            ))
        )
        .glassCard()
    }
    .padding()
}

#Preview("Dynamic Mode - Balanced") {
    VStack(spacing: 20) {
        PetModeInfoSection(
            modeInfo: .dynamic(.init(
                config: .balanced,
                limitedSources: LimitedSource.mockList()
            ))
        )
        .glassCard()
    }
    .padding()
}

#Preview("Dynamic Mode - Intense") {
    VStack(spacing: 20) {
        PetModeInfoSection(
            modeInfo: .dynamic(.init(
                config: .intense,
                limitedSources: LimitedSource.mockList()
            ))
        )
        .glassCard()
    }
    .padding()
}
#endif
