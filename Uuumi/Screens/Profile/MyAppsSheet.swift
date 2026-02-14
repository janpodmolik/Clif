import FamilyControls
import SwiftUI

struct MyAppsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var editSelection = FamilyActivitySelection()
    @State private var showDeleteConfirmation = false

    private let hadSavedSelection: Bool

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 12
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 16
        static let footerPadding: CGFloat = 16
        static let footerSpacing: CGFloat = 12
    }

    init() {
        hadSavedSelection = SharedDefaults.hasMyAppsSelection
    }

    private var hasSelection: Bool {
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
            .navigationTitle("Moje aplikace")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .alert("Smazat moje aplikace?", isPresented: $showDeleteConfirmation) {
                Button("Smazat", role: .destructive) {
                    SharedDefaults.clearMyAppsSelection()
                    dismiss()
                }
                Button("Zrušit", role: .cancel) {}
            } message: {
                Text("Uložený výběr bude smazán.")
            }
        }
        .onAppear {
            editSelection = SharedDefaults.loadMyAppsSelection() ?? FamilyActivitySelection()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            Text("Uložený výběr aplikací")
                .font(.title3.weight(.semibold))

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
            if hasSelection {
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
        .animation(.easeInOut(duration: 0.2), value: hasSelection)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Layout.footerSpacing) {
            saveButton

            if hadSavedSelection {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Smazat uložený výběr")
                        .font(.subheadline.weight(.medium))
                }
            }
        }
        .padding(.horizontal, Layout.footerPadding)
        .padding(.vertical, Layout.footerPadding)
        .background(footerBackground)
    }

    private var saveButton: some View {
        Button {
            SharedDefaults.saveMyAppsSelection(editSelection)
            dismiss()
        } label: {
            Text("Uložit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .tint(.blue)
        .disabled(!hasSelection)
    }

    @ViewBuilder
    private var footerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            MyAppsSheet()
        }
}
#endif
