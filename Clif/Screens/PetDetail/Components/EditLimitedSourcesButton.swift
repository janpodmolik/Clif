import FamilyControls
import SwiftUI

/// Compact premium button for changing limited sources.
/// Shows a pencil icon with a dots indicator for remaining changes.
/// Tapping opens FamilyActivityPicker in a sheet with confirmation.
struct EditLimitedSourcesButton: View {
    let changesUsed: Int
    let changesTotal: Int
    var onEdit: ((FamilyActivitySelection) -> Void)?

    @State private var showPicker = false
    @State private var editSelection = FamilyActivitySelection()
    @State private var showConfirmation = false

    private var remainingChanges: Int {
        changesTotal - changesUsed
    }

    private var hasEditSelection: Bool {
        !editSelection.applicationTokens.isEmpty
            || !editSelection.categoryTokens.isEmpty
            || !editSelection.webDomainTokens.isEmpty
    }

    var body: some View {
        Button {
            editSelection = SharedDefaults.loadFamilyActivitySelection() ?? FamilyActivitySelection()
            showPicker = true
        } label: {
            Image(systemName: "pencil")
                .font(.body.weight(.semibold))
                .frame(maxWidth: 56, maxHeight: .infinity)
                .glassCard()
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            pickerSheet
        }
    }

    // MARK: - Picker Sheet

    private var pickerSheet: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $editSelection)
                .navigationTitle("Změnit aplikace")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Zrušit") {
                            showPicker = false
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Uložit") {
                            showConfirmation = true
                        }
                        .fontWeight(.semibold)
                        .disabled(!hasEditSelection)
                    }
                }
                .alert("Změnit sledované aplikace?", isPresented: $showConfirmation) {
                    Button("Změnit", role: .destructive) {
                        onEdit?(editSelection)
                        showPicker = false
                    }
                    Button("Zrušit", role: .cancel) {}
                } message: {
                    Text("Po této změně ti \(remainingChangesText(after: remainingChanges - 1)).")
                }
        }
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
#Preview {
    HStack(spacing: 12) {
        LimitedAppsButton(
            sources: LimitedSource.mockList(),
            onTap: {}
        )

        EditLimitedSourcesButton(
            changesUsed: 1,
            changesTotal: 3
        ) { _ in }
    }
    .padding()
}
#endif
