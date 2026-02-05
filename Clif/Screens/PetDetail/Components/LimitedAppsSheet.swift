import FamilyControls
import SwiftUI

/// Sheet displaying limited apps, categories, and websites grouped by type.
/// Shows only icon and name (no usage minutes - Apple API limitation).
/// Optionally shows a sticky footer with edit button when changes are available.
struct LimitedAppsSheet: View {
    let sources: [LimitedSource]
    var changesUsed: Int?
    var changesTotal: Int?
    var onEdit: ((FamilyActivitySelection) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

    private var sourcesWithTokens: [LimitedSource] {
        sources.filter(\.hasToken)
    }

    private var apps: [LimitedSource] {
        sourcesWithTokens.filter { $0.kind == .app }
    }

    private var categories: [LimitedSource] {
        sourcesWithTokens.filter { $0.kind == .category }
    }

    private var websites: [LimitedSource] {
        sourcesWithTokens.filter { $0.kind == .website }
    }

    private var canEdit: Bool {
        guard let used = changesUsed, let total = changesTotal else { return false }
        return used < total && onEdit != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        if sourcesWithTokens.isEmpty {
                            emptyState
                        } else {
                            if !apps.isEmpty {
                                sourceSection(title: "Aplikace", icon: "app.fill", sources: apps)
                            }

                            if !categories.isEmpty {
                                sourceSection(title: "Kategorie", icon: "square.grid.2x2.fill", sources: categories)
                            }

                            if !websites.isEmpty {
                                sourceSection(title: "Webové stránky", icon: "globe", sources: websites)
                            }
                        }
                    }
                    .padding()
                }

                if canEdit {
                    editFooter
                }
            }
            .navigationTitle("Sledované aplikace")
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
            .sheet(isPresented: $showEditSheet) {
                if let changesUsed, let changesTotal {
                    EditLimitedSourcesSheet(
                        changesUsed: changesUsed,
                        changesTotal: changesTotal
                    ) { selection in
                        onEdit?(selection)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Edit Footer

    private var editFooter: some View {
        VStack(spacing: 10) {
            if let used = changesUsed, let total = changesTotal {
                HStack(spacing: 8) {
                    ChangesIndicator(used: used, total: total)

                    Text(changesInfoText(remaining: total - used))
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }

            Button {
                showEditSheet = true
            } label: {
                Text("Změnit aplikace")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Sections

    private func sourceSection(title: String, icon: String, sources: [LimitedSource]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    SourceRow(source: source)

                    if index < sources.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.vertical, 8)
            .glassCard()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Žádné sledované aplikace", systemImage: "app.badge")
        } description: {
            Text("Přidej aplikace, které chceš sledovat, v nastavení limitu.")
        }
        .padding()
        .glassCard()
    }

    // MARK: - Helpers

    private func changesInfoText(remaining: Int) -> String {
        switch remaining {
        case 0: "Žádná zbývající změna"
        case 1: "Zbývá 1 změna"
        case 2, 3, 4: "Zbývají \(remaining) změny"
        default: "Zbývá \(remaining) změn"
        }
    }
}

// MARK: - Source Row

private struct SourceRow: View {
    let source: LimitedSource

    private let iconSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            sourceIcon
            sourceLabel
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var sourceLabel: some View {
        switch source {
        case .app(let appSource):
            if let token = appSource.applicationToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }

        case .category(let catSource):
            if let token = catSource.categoryToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }

        case .website(let webSource):
            if let token = webSource.webDomainToken {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch source {
        case .app(let appSource):
            if let token = appSource.applicationToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .category(let catSource):
            if let token = catSource.categoryToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .website(let webSource):
            if let token = webSource.webDomainToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#if DEBUG
#Preview("With Sources") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changesUsed: 1,
        changesTotal: 3
    ) { _ in }
}

#Preview("No changes left") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changesUsed: 3,
        changesTotal: 3
    )
}

#Preview("Empty") {
    LimitedAppsSheet(sources: [])
}
#endif
