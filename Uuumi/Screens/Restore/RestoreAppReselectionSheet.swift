import FamilyControls
import SwiftUI

/// Sheet shown after cloud restore when tokens are invalid (reinstall).
/// Two phases:
/// 1. **Intro** — pet info, "Znovu povolit" button + archive/delete
/// 2. **Picker** — after authorization, FamilyActivityPicker for app re-selection
///
/// Restore is always allowed regardless of daily change limit.
/// Non-dismissable — user must complete selection or decide pet's fate.
struct RestoreAppReselectionSheet: View {
    enum Action {
        case reauthorize
        case save(FamilyActivitySelection)
        case archive
        case delete
    }

    let petName: String
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
            switch phase {
            case .intro:
                introContent
            case .picker:
                pickerContent
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
                title: "\(petName) is back!",
                subtitle: "After reinstalling, you need to reauthorize Screen Time access and select tracked apps."
            )

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
                    Text("Reauthorize")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Grants access and allows app selection")
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
        if canArchive {
            ConfirmationAction(
                icon: "archivebox",
                title: "Archive",
                subtitle: "Preserves history in overview",
                background: .material,
                action: { Task { try? await onAction?(.archive) } }
            )
        }

        ConfirmationAction(
            icon: "trash",
            title: "Delete permanently",
            subtitle: "Removes all data",
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
                title: "\(petName) is back!",
                subtitle: "Select tracked apps."
            )
        }
        .padding(.horizontal, Layout.headerPadding)
        .padding(.vertical, Layout.headerPadding)
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: Layout.headerCornerRadius)
        .padding(.horizontal, Layout.headerPadding)
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        Button {
            Task { try? await onAction?(.save(selection)) }
        } label: {
            Text("Confirm selection")
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
#Preview("Intro") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RestoreAppReselectionSheet(
                petName: "Fern",
                canArchive: true
            )
        }
}

#Preview("Intro - Too Young") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            RestoreAppReselectionSheet(
                petName: "Sprout",
                canArchive: false
            )
        }
}
#endif
