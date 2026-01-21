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
                    applicationTokens: coordinator.selectedApps.applicationTokens,
                    categoryTokens: coordinator.selectedApps.categoryTokens,
                    webDomainTokens: coordinator.selectedApps.webDomainTokens
                )
            }

            // Mode (show after step 1)
            if coordinator.currentStep.rawValue >= CreatePetStep.modeConfig.rawValue {
                if hasAppsSelected {
                    divider
                }

                HStack(spacing: 4) {
                    Image(systemName: coordinator.selectedMode.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(coordinator.selectedMode.themeColor)

                    Text(coordinator.selectedMode.shortName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Limit value (show after step 2)
            if coordinator.currentStep.rawValue >= CreatePetStep.petInfo.rawValue {
                divider

                Text(limitDisplayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Pet name (show after step 3, only if entered)
            if coordinator.currentStep.rawValue >= CreatePetStep.petDrop.rawValue,
               !coordinator.petName.isEmpty
            {
                divider

                Text(coordinator.petName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
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

    private var limitDisplayText: String {
        if coordinator.selectedMode == .daily {
            return MinutesFormatter.compact(coordinator.dailyLimitMinutes)
        } else {
            return coordinator.dynamicConfig.displayName
        }
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
