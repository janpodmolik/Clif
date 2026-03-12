import FamilyControls
import SwiftUI

struct WelcomeBackPickerPhase: View {
    @Binding var appSelection: FamilyActivitySelection
    let onConfirm: () -> Void
    let onBack: () -> Void

    @State private var pickerID = UUID()
    @Environment(\.colorScheme) private var colorScheme

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 12
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 16
        static let footerPadding: CGFloat = 16
    }

    private var hasSelection: Bool {
        !appSelection.applicationTokens.isEmpty
            || !appSelection.categoryTokens.isEmpty
            || !appSelection.webDomainTokens.isEmpty
    }

    private var selectionMatchesSaved: Bool {
        guard let saved = SharedDefaults.loadMyAppsSelection() else { return false }
        return appSelection.applicationTokens == saved.applicationTokens
            && appSelection.categoryTokens == saved.categoryTokens
            && appSelection.webDomainTokens == saved.webDomainTokens
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : .white
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .zIndex(1)

            FamilyActivityPicker(selection: $appSelection)
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

            footer
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zpět", action: onBack)
            }
        }
    }

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            Text("Vyber sledované aplikace")
                .font(.title3.weight(.semibold))

            selectionSummary

            if !selectionMatchesSaved {
                MyAppsLoadButton(selection: $appSelection) {
                    pickerID = UUID()
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
    }

    @ViewBuilder
    private var selectionSummary: some View {
        HStack(spacing: 8) {
            if hasSelection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                LimitedSourcesPreview(
                    applicationTokens: Array(appSelection.applicationTokens),
                    categoryTokens: appSelection.categoryTokens,
                    webDomainTokens: appSelection.webDomainTokens
                )
            } else {
                Text("Klepni a vyber aplikace nebo kategorie")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 28)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: hasSelection)
    }

    private var footer: some View {
        Button(action: onConfirm) {
            Text("Potvrdit výběr")
        }
        .buttonStyle(.primary)
        .disabled(!hasSelection)
        .padding(.horizontal, Layout.footerPadding)
        .padding(.vertical, Layout.footerPadding)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
