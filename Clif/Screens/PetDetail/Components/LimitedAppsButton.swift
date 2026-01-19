import FamilyControls
import ManagedSettings
import SwiftUI

struct LimitedAppsButton: View {
    let apps: [LimitedApp]
    let categories: [LimitedCategory]
    var onTap: (() -> Void)?

    private var applicationTokens: Set<ApplicationToken> {
        Set(apps.compactMap(\.applicationToken))
    }

    private var categoryTokens: Set<ActivityCategoryToken> {
        Set(categories.compactMap(\.categoryToken))
    }

    private var hasValidTokens: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty
    }

    private var subtitleText: String {
        var parts: [String] = []

        if !apps.isEmpty {
            parts.append("\(apps.count) \(apps.count == 1 ? "app" : "apps")")
        }
        if !categories.isEmpty {
            parts.append("\(categories.count) \(categories.count == 1 ? "category" : "categories")")
        }
        // TODO: Add webDomains when available

        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Limited Apps")
                        .font(.subheadline.weight(.medium))

                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if hasValidTokens {
                    LimitedAppsPreview(
                        applicationTokens: applicationTokens,
                        categoryTokens: categoryTokens
                    )
                }

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .buttonStyle(.plain)
        .glassCard()
    }
}

#if DEBUG
#Preview("With tokens (mock)") {
    VStack(spacing: 16) {
        LimitedAppsButton(
            apps: LimitedApp.mockList(),
            categories: LimitedCategory.mockList(),
            onTap: {}
        )
    }
    .padding()
}

#Preview("Without tokens (archived)") {
    VStack(spacing: 16) {
        LimitedAppsButton(
            apps: LimitedApp.mockList(),
            categories: LimitedCategory.mockList(),
            onTap: {}
        )
        LimitedAppsButton(
            apps: LimitedApp.mockList(),
            categories: []
        )
    }
    .padding()
}
#endif
