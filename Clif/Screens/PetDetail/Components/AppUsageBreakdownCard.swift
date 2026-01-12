import FamilyControls
import ManagedSettings
import SwiftUI

struct AppUsageBreakdownCard: View {
    let appUsage: [AppUsage]
    var forDate: Date? = nil
    var maxVisible: Int = 5
    var themeColor: Color = .green

    @State private var showAllApps = false

    private var sortedApps: [AppUsage] {
        appUsage.sorted { minutesFor($0) > minutesFor($1) }
    }

    private var visibleApps: [AppUsage] {
        Array(sortedApps.prefix(maxVisible))
    }

    private var hiddenCount: Int {
        max(0, sortedApps.count - maxVisible)
    }

    private var maxMinutes: Int {
        sortedApps.first.map { minutesFor($0) } ?? 1
    }

    private func minutesFor(_ app: AppUsage) -> Int {
        if let date = forDate {
            return app.minutes(for: date) ?? 0
        }
        return app.totalMinutes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            ForEach(visibleApps) { app in
                appRow(app)
            }

            if hiddenCount > 0 {
                showMoreButton
            }
        }
        .padding()
        .glassCard()
        .sheet(isPresented: $showAllApps) {
            AllAppsSheet(
                apps: sortedApps,
                forDate: forDate,
                themeColor: themeColor
            )
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: "app.badge")
                .foregroundStyle(.secondary)

            Text("Aplikace")
                .font(.headline)

            Spacer()

            Text("Celkem")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - App Row

    private func appRow(_ app: AppUsage) -> some View {
        HStack(spacing: 12) {
            appIcon(for: app)

            Text(app.displayName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            progressBar(minutes: minutesFor(app))

            Text(formatMinutes(minutesFor(app)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func appIcon(for app: AppUsage) -> some View {
        if let token = app.applicationToken {
            Label(token)
                .labelStyle(.iconOnly)
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Text(String(app.displayName.prefix(1)))
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(themeColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func progressBar(minutes: Int) -> some View {
        let progress = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(maxMinutes) : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.08))

                RoundedRectangle(cornerRadius: 3)
                    .fill(themeColor.opacity(0.7))
                    .frame(width: max(4, geo.size.width * progress))
            }
        }
        .frame(width: 60, height: 6)
    }

    // MARK: - Show More

    private var showMoreButton: some View {
        Button {
            showAllApps = true
        } label: {
            HStack {
                Spacer()
                Text("Zobrazit více (\(hiddenCount))")
                Image(systemName: "chevron.right")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

// MARK: - All Apps Sheet

private struct AllAppsSheet: View {
    let apps: [AppUsage]
    let forDate: Date?
    let themeColor: Color

    @Environment(\.dismiss) private var dismiss

    private func minutesFor(_ app: AppUsage) -> Int {
        if let date = forDate {
            return app.minutes(for: date) ?? 0
        }
        return app.totalMinutes
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(apps) { app in
                    appRow(app)
                }
            }
            .navigationTitle("Všechny aplikace")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func appRow(_ app: AppUsage) -> some View {
        HStack(spacing: 12) {
            appIcon(for: app)

            Text(app.displayName)
                .font(.subheadline)

            Spacer()

            Text(formatMinutes(minutesFor(app)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func appIcon(for app: AppUsage) -> some View {
        if let token = app.applicationToken {
            Label(token)
                .labelStyle(.iconOnly)
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Text(String(app.displayName.prefix(1)))
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(themeColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }
}

#if DEBUG
#Preview {
    AppUsageBreakdownCard(appUsage: AppUsage.mockList(days: 14))
        .padding()
}

#Preview("Few apps") {
    AppUsageBreakdownCard(
        appUsage: Array(AppUsage.mockList(days: 14).prefix(3)),
        themeColor: .purple
    )
    .padding()
}

#Preview("Single day") {
    AppUsageBreakdownCard(
        appUsage: AppUsage.mockList(days: 14),
        forDate: Date(),
        themeColor: .blue
    )
    .padding()
}
#endif
