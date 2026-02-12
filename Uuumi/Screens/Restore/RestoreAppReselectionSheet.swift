import FamilyControls
import SwiftUI

/// Sheet shown after cloud restore when tokens are invalid (reinstall).
/// Three phases:
/// 1. **Intro** — pet info, changes remaining, "Znovu povolit" button + blow away/archive/delete
/// 2. **Picker** — after authorization, FamilyActivityPicker for app re-selection
/// 3. **Exhausted** — no changes remaining, only blow away/archive/delete
///
/// Non-dismissable — user must complete selection or decide pet's fate.
struct RestoreAppReselectionSheet: View {
    enum Action {
        case reauthorize
        case save(FamilyActivitySelection)
        case blowAway
        case archive
        case delete
    }

    let petName: String
    let changesUsed: Int
    let changesTotal: Int
    let canChange: Bool
    let canArchive: Bool
    var onAction: ((Action) async throws -> Void)?

    @State private var phase: Phase = .intro
    @State private var selection = FamilyActivitySelection()
    @State private var isAuthorizing = false

    private enum Phase {
        case intro, picker
    }

    private enum Layout {
        static let headerSpacing: CGFloat = 8
        static let headerPadding: CGFloat = 12
        static let headerCornerRadius: CGFloat = 20
        static let fadeHeight: CGFloat = 16
        static let footerPadding: CGFloat = 16
    }

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    var body: some View {
        NavigationStack {
            if !canChange {
                exhaustedContent
            } else {
                switch phase {
                case .intro:
                    introContent
                case .picker:
                    pickerContent
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Intro Content (authorize + decide)

    private var introContent: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            ConfirmationHeader(
                icon: "arrow.clockwise.icloud",
                iconColor: .blue,
                title: "\(petName) je zpátky!",
                subtitle: "Po reinstalaci je potřeba znovu povolit přístup k času u obrazovky a vybrat sledované aplikace."
            )

            changesInfo

            VStack(spacing: 12) {
                reauthorizeButton
                fateActions
            }

            Spacer()
        }
        .padding(24)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Picker Content (post-authorization)

    private var pickerContent: some View {
        VStack(spacing: 0) {
            pickerHeader
                .zIndex(1)

            FamilyActivityPicker(selection: $selection)
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
    }

    // MARK: - Exhausted Content (no changes remaining)

    private var exhaustedContent: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            ConfirmationHeader(
                icon: "app.badge",
                iconColor: .orange,
                title: "Změny vyčerpány",
                subtitle: "\(petName) nemůže pokračovat bez sledovaných aplikací. Vyčerpal jsi všechny změny."
            )

            ChangesIndicator(used: changesUsed, total: changesTotal)

            VStack(spacing: 12) {
                fateActions
            }

            Spacer()
        }
        .padding(24)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Shared Components

    private var reauthorizeButton: some View {
        Button {
            Task { await authorize() }
        } label: {
            HStack(spacing: 12) {
                if isAuthorizing {
                    ProgressView()
                } else {
                    Image(systemName: "checkmark.shield")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Znovu povolit")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Povolí přístup a umožní výběr aplikací")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isAuthorizing)
    }

    @ViewBuilder
    private var fateActions: some View {
        ConfirmationAction(
            icon: "wind",
            title: "Odfouknout",
            subtitle: "\(petName) bude odfouknut větrem",
            foregroundColor: .red,
            background: .tinted(.red),
            action: { Task { try? await onAction?(.blowAway) } }
        )

        if canArchive {
            ConfirmationAction(
                icon: "archivebox",
                title: "Archivovat",
                subtitle: "Zachová historii v přehledu",
                background: .material,
                action: { Task { try? await onAction?(.archive) } }
            )
        }

        ConfirmationAction(
            icon: "trash",
            title: "Smazat trvale",
            subtitle: "Odstraní všechna data",
            foregroundColor: .red,
            background: .tinted(.red),
            action: { Task { try? await onAction?(.delete) } }
        )
    }

    // MARK: - Picker Header

    private var pickerHeader: some View {
        VStack(spacing: Layout.headerSpacing) {
            ConfirmationHeader(
                icon: "arrow.clockwise.icloud",
                iconColor: .blue,
                title: "\(petName) je zpátky!",
                subtitle: "Vyber sledované aplikace."
            )

            changesInfo
        }
        .padding(.horizontal, Layout.headerPadding)
        .padding(.vertical, Layout.headerPadding)
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: Layout.headerCornerRadius)
        .padding(.horizontal, Layout.headerPadding)
        .padding(.top, 8)
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
        let remaining = changesTotal - changesUsed
        switch remaining {
        case 0: return "Žádná zbývající změna"
        case 1: return "Zbývá 1 změna"
        case 2, 3, 4: return "Zbývají \(remaining) změny"
        default: return "Zbývá \(remaining) změn"
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Button {
            Task { try? await onAction?(.save(selection)) }
        } label: {
            Text("Potvrdit výběr")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(hasSelection ? Color(.label) : Color.gray.opacity(0.3), in: Capsule())
        }
        .disabled(!hasSelection)
        .padding(.horizontal, Layout.footerPadding)
        .padding(.vertical, Layout.footerPadding)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Authorization

    private func authorize() async {
        isAuthorizing = true
        do {
            try await onAction?(.reauthorize)
            withAnimation {
                phase = .picker
            }
        } catch {
            // Authorization failed — stay on intro, user can retry or choose another option
        }
        isAuthorizing = false
    }
}

#if DEBUG
#Preview("Intro (Can Change)") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RestoreAppReselectionSheet(
                petName: "Fern",
                changesUsed: 1,
                changesTotal: 3,
                canChange: true,
                canArchive: true
            )
        }
}

#Preview("Changes Exhausted - Can Archive") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RestoreAppReselectionSheet(
                petName: "Fern",
                changesUsed: 3,
                changesTotal: 3,
                canChange: false,
                canArchive: true
            )
        }
}

#Preview("Changes Exhausted - Too Young") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RestoreAppReselectionSheet(
                petName: "Sprout",
                changesUsed: 3,
                changesTotal: 3,
                canChange: false,
                canArchive: false
            )
        }
}
#endif
