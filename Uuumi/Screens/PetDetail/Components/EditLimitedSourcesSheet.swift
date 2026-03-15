import FamilyControls
import SwiftUI

/// Full-screen sheet for editing limited sources.
/// Layout mirrors the pet creation flow: header overview on top,
/// FamilyActivityPicker in the middle, sticky save button at bottom.
struct EditLimitedSourcesSheet: View {
    let changeState: LimitedSourceChangeState
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
            .alert("Change tracked apps?", isPresented: $showConfirmation) {
                Button("Change", role: .destructive) {
                    if saveAsMyApps {
                        SharedDefaults.saveMyAppsSelection(editSelection)
                    }
                    onSave?(editSelection)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(confirmationMessage)
            }
        }
        .onAppear {
            editSelection = SharedDefaults.loadFamilyActivitySelection() ?? FamilyActivitySelection()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            Text("Tracked Apps")
                .font(.title3.weight(.semibold))

            MyAppsLoadButton(
                selection: $editSelection,
                infoMessage: "Load your saved app selection, or edit and save it again. You can manage your saved selection in Profile."
            ) {
                pickerID = UUID()
            }

            selectionSummary
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
                Text("Select apps or categories")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 28)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: hasEditSelection)
    }

    private var confirmationMessage: String {
        switch changeState {
        case .unlimited:
            "Your tracked app selection will be updated."
        case .available:
            "After this change, you can change again tomorrow."
        case .usedToday, .blown:
            "No more changes available today."
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
            Text("Save changes")
        }
        .buttonStyle(.primary)
        .disabled(!hasEditSelection)
    }

    @ViewBuilder
    private var footerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
    }
}

#if DEBUG
#Preview("Unlimited (blob)") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EditLimitedSourcesSheet(
                changeState: .unlimited
            ) { _ in }
        }
}

#Preview("Available") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            EditLimitedSourcesSheet(
                changeState: .available
            ) { _ in }
        }
}
#endif
