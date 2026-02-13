import FamilyControls
import SwiftUI

struct AppSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    @Environment(\.colorScheme) private var colorScheme

    @State private var pickerID = UUID()

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 12
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 16
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : .white
    }

    private var selectionMatchesSaved: Bool {
        guard let saved = SharedDefaults.loadMyAppsSelection() else { return false }
        let sel = coordinator.selectedApps
        return sel.applicationTokens == saved.applicationTokens
            && sel.categoryTokens == saved.categoryTokens
            && sel.webDomainTokens == saved.webDomainTokens
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        VStack(spacing: 0) {
            // Header with glass background
            VStack(spacing: Layout.headerSpacing) {
                Text("Select what to limit")
                    .font(.title3.weight(.semibold))

                selectionSummary

                if !selectionMatchesSaved {
                    HStack(spacing: 8) {
                        MyAppsLoadButton(selection: $coordinator.selectedApps) {
                            pickerID = UUID()
                        }

                        MyAppsInfoButton(message: "Načte tvůj uložený výběr aplikací a kategorií. Uložený výběr můžeš spravovat v Profilu.")
                    }
                    .padding(.top, 4)
                }
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
                .id(pickerID)
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

    // MARK: - Selection Summary

    @ViewBuilder
    private var selectionSummary: some View {
        let selection = coordinator.selectedApps
        let hasAny = !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty

        HStack(spacing: 8) {
            if hasAny {
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
        .frame(height: 28)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: hasAny)
    }
}

#if DEBUG
#Preview {
    AppSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
