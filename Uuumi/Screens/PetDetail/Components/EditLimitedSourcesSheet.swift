import FamilyControls
import SwiftUI

/// Full-screen sheet for editing limited sources.
/// Layout mirrors the pet creation flow: header overview on top,
/// FamilyActivityPicker in the middle, sticky save button at bottom.
struct EditLimitedSourcesSheet: View {
    let changesUsed: Int
    let changesTotal: Int
    var onSave: ((FamilyActivitySelection) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var editSelection = FamilyActivitySelection()
    @State private var showConfirmation = false
    @State private var pickerID = UUID()
    @State private var saveAsMyApps = false

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 12
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 16
        static let footerPadding: CGFloat = 16
    }

    private var remainingChanges: Int {
        changesTotal - changesUsed
    }

    private var hasEditSelection: Bool {
        !editSelection.applicationTokens.isEmpty
            || !editSelection.categoryTokens.isEmpty
            || !editSelection.webDomainTokens.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .zIndex(1)

                FamilyActivityPicker(selection: $editSelection)
                    .id(pickerID)
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: Layout.fadeHeight)
                        .allowsHitTesting(false)
                    }

                footer
            }
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .alert("Změnit sledované aplikace?", isPresented: $showConfirmation) {
                Button("Změnit", role: .destructive) {
                    if saveAsMyApps {
                        SharedDefaults.saveMyAppsSelection(editSelection)
                    }
                    onSave?(editSelection)
                    dismiss()
                }
                Button("Zrušit", role: .cancel) {}
            } message: {
                Text("Po této změně ti \(remainingChangesText(after: remainingChanges - 1)).")
            }
        }
        .onAppear {
            editSelection = SharedDefaults.loadFamilyActivitySelection() ?? FamilyActivitySelection()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            HStack {
                Text("Sledované aplikace")
                    .font(.title3.weight(.semibold))

                MyAppsInfoButton(message: "Načti si uložený výběr aplikací, nebo ho uprav a ulož znovu. Uložený výběr můžeš spravovat v Profilu.")
            }

            MyAppsLoadButton(selection: $editSelection) {
                pickerID = UUID()
            }

            selectionSummary

            changesInfo
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
            if hasEditSelection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                LimitedSourcesPreview(
                    applicationTokens: Array(editSelection.applicationTokens),
                    categoryTokens: editSelection.categoryTokens,
                    webDomainTokens: editSelection.webDomainTokens
                )
            } else {
                Text("Vyber aplikace nebo kategorie")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 28)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: hasEditSelection)
    }

    private var changesInfo: some View {
        HStack(spacing: 8) {
            ChangesIndicator(used: changesUsed, total: changesTotal)

            Text(changesInfoText)
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
    }

    private var changesInfoText: String {
        let remaining = remainingChanges
        switch remaining {
        case 0: return "Žádná zbývající změna"
        case 1: return "Zbývá 1 změna"
        case 2, 3, 4: return "Zbývají \(remaining) změny"
        default: return "Zbývá \(remaining) změn"
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            SaveAsMyAppsToggle(isOn: $saveAsMyApps)

            saveButton
        }
        .padding(.horizontal, Layout.footerPadding)
        .padding(.vertical, Layout.footerPadding)
        .background(footerBackground)
    }

    private var saveButton: some View {
        Button {
            showConfirmation = true
        } label: {
            Text("Uložit změny")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .tint(.blue)
        .disabled(!hasEditSelection)
    }

    @ViewBuilder
    private var footerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Helpers

    private func remainingChangesText(after count: Int) -> String {
        switch count {
        case 0: "nezbývá žádná další změna"
        case 1: "zbývá 1 změna"
        case 2, 3, 4: "zbývají \(count) změny"
        default: "zbývá \(count) změn"
        }
    }
}

#if DEBUG
#Preview("Fresh - 0 changes used") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EditLimitedSourcesSheet(
                changesUsed: 0,
                changesTotal: 3
            ) { _ in }
        }
}

#Preview("2 changes used") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EditLimitedSourcesSheet(
                changesUsed: 2,
                changesTotal: 3
            ) { _ in }
        }
}
#endif
