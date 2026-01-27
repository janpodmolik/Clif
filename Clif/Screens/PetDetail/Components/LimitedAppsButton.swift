import FamilyControls
import ManagedSettings
import SwiftUI

struct LimitedAppsButton: View {
    let sources: [LimitedSource]
    var onTap: (() -> Void)?

    private var appSources: [AppSource] {
        sources.compactMap {
            if case .app(let source) = $0 { return source }
            return nil
        }
    }

    private var categorySources: [CategorySource] {
        sources.compactMap {
            if case .category(let source) = $0 { return source }
            return nil
        }
    }

    private var websiteSources: [WebsiteSource] {
        sources.compactMap {
            if case .website(let source) = $0 { return source }
            return nil
        }
    }

    private var applicationTokens: Set<ApplicationToken> {
        Set(appSources.compactMap(\.applicationToken))
    }

    private var categoryTokens: Set<ActivityCategoryToken> {
        Set(categorySources.compactMap(\.categoryToken))
    }

    private var webDomainTokens: Set<WebDomainToken> {
        Set(websiteSources.compactMap(\.webDomainToken))
    }

    private var hasValidTokens: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
    }

    private var subtitleText: String {
        var parts: [String] = []

        let appCount = appSources.count
        if appCount > 0 {
            parts.append("\(appCount) \(appCount == 1 ? "app" : "apps")")
        }

        let categoryCount = categorySources.count
        if categoryCount > 0 {
            parts.append("\(categoryCount) \(categoryCount == 1 ? "category" : "categories")")
        }

        let websiteCount = websiteSources.count
        if websiteCount > 0 {
            parts.append("\(websiteCount) \(websiteCount == 1 ? "website" : "websites")")
        }

        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Limited Apps")
                        .font(.subheadline.weight(.medium))

                    if hasValidTokens {
                        LimitedSourcesPreview(
                            applicationTokens: applicationTokens,
                            categoryTokens: categoryTokens,
                            webDomainTokens: webDomainTokens
                        )
                    } else {
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassCard()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("With tokens (mock)") {
    VStack(spacing: 16) {
        LimitedAppsButton(
            sources: LimitedSource.mockList(),
            onTap: {}
        )
    }
    .padding()
}

#Preview("Without tokens (archived)") {
    VStack(spacing: 16) {
        LimitedAppsButton(
            sources: LimitedSource.mockList(),
            onTap: {}
        )
        LimitedAppsButton(
            sources: LimitedSource.mockList().filter { $0.kind == .app }
        )
    }
    .padding()
}
#endif
