import FamilyControls
import SwiftUI

/// State of limited source change availability.
enum LimitedSourceChangeState {
    case unlimited      // before essence (blob) — no restrictions
    case available      // after essence, not changed today
    case usedToday      // after essence, already changed today
    case blown          // pet is blown away — no changes allowed
}

/// Sheet displaying limited apps, categories, and websites grouped by type.
/// Shows only icon and name (no usage minutes - Apple API limitation).
/// Optionally shows a sticky footer with edit button when changes are available.
struct LimitedAppsSheet: View {
    let sources: [LimitedSource]
    var changeState: LimitedSourceChangeState?
    var activeBreakType: BreakType?
    var onEdit: ((FamilyActivitySelection) -> Void)?
    var onEndFreeBreak: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showBlockedAlert: BlockedReason?
    @State private var showChangeInfo = false

    private enum BlockedReason: Identifiable {
        case freeBreak   // free break -> can end break
        case otherBreak  // committed/safety break

        var id: Self { self }
    }

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

    private var showFooter: Bool {
        changeState != nil && onEdit != nil
    }

    private var canEdit: Bool {
        guard let changeState else { return false }
        return changeState == .unlimited || changeState == .available
    }

    private var blockedReason: BlockedReason? {
        if let breakType = activeBreakType {
            return breakType == .free ? .freeBreak : .otherBreak
        }
        return nil
    }

    var body: some View {
        NavigationStack {
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
            .safeAreaInset(edge: .bottom) {
                if showFooter {
                    editFooter
                }
            }
            .navigationTitle("Sledované aplikace")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .sheet(isPresented: $showEditSheet) {
                if let changeState {
                    EditLimitedSourcesSheet(
                        changeState: changeState
                    ) { selection in
                        onEdit?(selection)
                        dismiss()
                    }
                }
            }
            .alert("Nelze změnit aplikace", isPresented: .init(
                get: { showBlockedAlert != nil },
                set: { if !$0 { showBlockedAlert = nil } }
            ), presenting: showBlockedAlert) { reason in
                if case .freeBreak = reason {
                    Button("Ukončit pauzu", role: .destructive) {
                        onEndFreeBreak?()
                    }
                }
                Button("Rozumím", role: .cancel) {}
            } message: { reason in
                switch reason {
                case .freeBreak:
                    Text("Během aktivní pauzy nelze měnit sledované aplikace. Nejdřív ukonči pauzu.")
                case .otherBreak:
                    Text("Během aktivní pauzy nelze měnit sledované aplikace.")
                }
            }
            .alert("Změny aplikací", isPresented: $showChangeInfo) {
                Button("OK") {}
            } message: {
                Text("Dokud tvůj pet nemá essenci, můžeš měnit sledované aplikace bez omezení. Po získání essence je možná 1 změna denně.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Edit Footer

    private var editFooter: some View {
        VStack(spacing: 10) {
            if let changeState {
                changeStateRow(changeState)
            }

            Button {
                if let reason = blockedReason {
                    showBlockedAlert = reason
                } else {
                    showEditSheet = true
                }
            } label: {
                Text("Změnit aplikace")
            }
            .buttonStyle(.primary)
            .disabled(!canEdit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func changeStateRow(_ state: LimitedSourceChangeState) -> some View {
        HStack(spacing: 6) {
            Text(changeStateText(state))
                .font(.footnote.weight(.medium))
                .foregroundStyle(changeStateColor(state))

            Button {
                showChangeInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.footnote)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
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

    private func changeStateText(_ state: LimitedSourceChangeState) -> String {
        switch state {
        case .unlimited: "Neomezené změny"
        case .available: "Zbývá 1/1 změna dnes"
        case .usedToday: "Vyčerpáno 1/1 — obnoví se zítra"
        case .blown: "Pet je odfouknutý"
        }
    }

    private func changeStateColor(_ state: LimitedSourceChangeState) -> Color {
        switch state {
        case .unlimited: .green
        case .available: .blue
        case .usedToday: .orange
        case .blown: .red
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
#Preview("With Sources - Available") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changeState: .available,
        onEdit: { _ in }
    )
}

#Preview("With Sources - Unlimited (blob)") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changeState: .unlimited,
        onEdit: { _ in }
    )
}

#Preview("Free Break") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changeState: .available,
        activeBreakType: .free,
        onEdit: { _ in },
        onEndFreeBreak: {}
    )
}

#Preview("Used Today") {
    LimitedAppsSheet(
        sources: LimitedSource.mockList(),
        changeState: .usedToday
    )
}

#Preview("Empty") {
    LimitedAppsSheet(sources: [])
}
#endif
