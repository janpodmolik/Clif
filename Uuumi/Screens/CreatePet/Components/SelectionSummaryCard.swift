import FamilyControls
import SwiftUI

struct SelectionSummaryCard: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 12
        static let spacing: CGFloat = 8
    }

    var body: some View {
        HStack(spacing: Layout.spacing) {
            // Apps/Categories
            if hasAppsSelected {
                LimitedSourcesPreview(
                    applicationTokens: Array(coordinator.selectedApps.applicationTokens),
                    categoryTokens: coordinator.selectedApps.categoryTokens,
                    webDomainTokens: coordinator.selectedApps.webDomainTokens
                )
            }

            // Preset (show after step 1)
            if coordinator.currentStep.rawValue >= CreatePetStep.presetSelection.rawValue {
                if hasAppsSelected {
                    divider
                }

                HStack(spacing: 4) {
                    Image(systemName: coordinator.preset.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(coordinator.preset.themeColor)

                    Text(coordinator.preset.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Layout.padding)
        .glassBackground(cornerRadius: Layout.cornerRadius)
        .animation(.easeInOut(duration: 0.2), value: coordinator.currentStep)
    }

    private var hasAppsSelected: Bool {
        !coordinator.selectedApps.applicationTokens.isEmpty
            || !coordinator.selectedApps.categoryTokens.isEmpty
            || !coordinator.selectedApps.webDomainTokens.isEmpty
    }

    private var divider: some View {
        Circle()
            .fill(.tertiary)
            .frame(width: 4, height: 4)
    }
}

#if DEBUG
#Preview {
    SelectionSummaryCard()
        .environment(CreatePetCoordinator())
        .padding()
}
#endif
