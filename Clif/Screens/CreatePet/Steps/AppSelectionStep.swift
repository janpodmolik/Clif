import FamilyControls
import SwiftUI

struct AppSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    @Environment(\.colorScheme) private var colorScheme

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 16
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 24
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : .white
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        VStack(spacing: 0) {
            // Header with glass background
            VStack(spacing: Layout.headerSpacing) {
                Text("Select apps to limit")
                    .font(.title3.weight(.semibold))

                Text("Choose which apps and categories your pet will monitor")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                selectionSummary
            }
            .padding(.horizontal, Layout.headerPadding)
            .padding(.vertical, Layout.headerPadding)
            .frame(maxWidth: .infinity)
            .glassBackground(cornerRadius: Layout.headerCornerRadius)
            .padding(.horizontal, Layout.headerPadding)
            .padding(.top, 8)
            .zIndex(1)

            // FamilyActivityPicker with fade overlay
            FamilyActivityPicker(selection: $coordinator.selectedApps)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [backgroundColor, backgroundColor.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Layout.fadeHeight)
                    .allowsHitTesting(false)
                }
        }
    }

    @ViewBuilder
    private var selectionSummary: some View {
        let selection = coordinator.selectedApps
        let hasSelection = !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty

        HStack(spacing: 8) {
            if hasSelection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                LimitedSourcesPreview(
                    applicationTokens: selection.applicationTokens,
                    categoryTokens: selection.categoryTokens,
                    webDomainTokens: selection.webDomainTokens
                )
            } else {
                Text("Tap to select apps or categories")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 28) // Match LimitedSourcesPreview icon height
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: hasSelection)
    }
}

#if DEBUG
#Preview {
    AppSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
