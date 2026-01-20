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
        .background(cardBackground)
        .animation(.easeInOut(duration: 0.2), value: coordinator.currentStep)
    }

    private var hasAppsSelected: Bool {
        !coordinator.selectedApps.applicationTokens.isEmpty
            || !coordinator.selectedApps.categoryTokens.isEmpty
            || !coordinator.selectedApps.webDomainTokens.isEmpty
    }

    private var limitDisplayText: String {
        if coordinator.selectedMode == .daily {
            let hours = coordinator.dailyLimitMinutes / 60
            let minutes = coordinator.dailyLimitMinutes % 60
            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        } else {
            return coordinator.dynamicConfig.displayName
        }
    }

    private var divider: some View {
        Circle()
            .fill(.tertiary)
            .frame(width: 4, height: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Layout.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
        } else {
            shape
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - PetMode Extensions

private extension PetMode {
    var iconName: String {
        switch self {
        case .daily: "clock.fill"
        case .dynamic: "wind"
        }
    }

    var shortName: String {
        switch self {
        case .daily: "Daily"
        case .dynamic: "Dynamic"
        }
    }

    var themeColor: Color {
        switch self {
        case .daily: .blue
        case .dynamic: .orange
        }
    }
}

#if DEBUG
#Preview {
    SelectionSummaryCard()
        .environment(CreatePetCoordinator())
        .padding()
}
#endif
