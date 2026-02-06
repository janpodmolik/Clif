import SwiftUI

// MARK: - Data Types

struct ConfirmationSheetHeader {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
}

struct ConfirmationSheetAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    var foregroundColor: Color? = nil
    var background: ConfirmationActionBackground = .material
    let action: () -> Void

    enum ConfirmationActionBackground {
        case tinted(Color)
        case material
    }
}

// MARK: - Container

/// Reusable confirmation sheet with NavigationStack chrome and presentation config.
/// Use the `@ViewBuilder` init for custom/reactive content, or the convenience init for static sheets.
struct ConfirmationSheet<Content: View>: View {
    let navigationTitle: String
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                content()
                Spacer()
            }
            .padding(24)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Static Convenience Init

extension ConfirmationSheet where Content == ConfirmationSheetStaticContent {
    init(
        navigationTitle: String,
        header: ConfirmationSheetHeader,
        actions: [ConfirmationSheetAction],
        height: CGFloat
    ) {
        self.init(
            navigationTitle: navigationTitle,
            height: height
        ) {
            ConfirmationSheetStaticContent(header: header, actions: actions)
        }
    }
}

struct ConfirmationSheetStaticContent: View {
    let header: ConfirmationSheetHeader
    let actions: [ConfirmationSheetAction]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ConfirmationHeader(
            icon: header.icon,
            iconColor: header.iconColor,
            title: header.title,
            subtitle: header.subtitle
        )

        VStack(spacing: 12) {
            ForEach(actions) { action in
                ConfirmationAction(
                    icon: action.icon,
                    title: action.title,
                    subtitle: action.subtitle,
                    foregroundColor: action.foregroundColor,
                    background: action.background
                ) {
                    dismiss()
                    action.action()
                }
            }
        }
    }
}

// MARK: - Header

/// Reusable header for confirmation sheets: icon + title + optional subtitle.
struct ConfirmationHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Action Row

/// Reusable action button row for confirmation sheets.
struct ConfirmationAction: View {
    let icon: String
    let title: String
    let subtitle: String
    var foregroundColor: Color? = nil
    var background: ConfirmationSheetAction.ConfirmationActionBackground = .material
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(foregroundColor ?? .primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(foregroundColor ?? .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundView)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch background {
        case .tinted(let color):
            color.opacity(0.15).clipShape(RoundedRectangle(cornerRadius: 12))
        case .material:
            RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Static - Single Action") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            ConfirmationSheet(
                navigationTitle: "Archive Pet",
                header: ConfirmationSheetHeader(
                    icon: "checkmark.seal.fill",
                    iconColor: .green,
                    title: "Fern reached max evolution!",
                    subtitle: "Archived pet will be stored in Overview but cannot be restored."
                ),
                actions: [
                    ConfirmationSheetAction(
                        icon: "archivebox",
                        title: "Archive",
                        subtitle: "Safely store in Overview",
                        background: .tinted(.green)
                    ) {}
                ],
                height: 320
            )
        }
}

#Preview("ViewBuilder - Multiple Actions") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            ConfirmationSheet(
                navigationTitle: "Odstranit peta",
                height: 340
            ) {
                ConfirmationHeader(
                    icon: "questionmark.circle",
                    iconColor: .orange,
                    title: "Co chceš udělat s Fern?"
                )

                VStack(spacing: 12) {
                    ConfirmationAction(
                        icon: "archivebox",
                        title: "Archivovat",
                        subtitle: "Zachová historii v přehledu"
                    ) {}

                    ConfirmationAction(
                        icon: "trash",
                        title: "Smazat trvale",
                        subtitle: "Odstraní všechna data",
                        foregroundColor: .red,
                        background: .tinted(.red)
                    ) {}
                }
            }
        }
}
#endif
