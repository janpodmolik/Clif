import SwiftUI

struct ArchiveStatusCard: View {
    let isBlown: Bool
    let archivedAt: Date

    private var statusText: String {
        isBlown ? "Odfouknut" : "Plně evolvován"
    }

    private var statusIcon: String {
        isBlown ? "wind" : "checkmark.circle.fill"
    }

    private var statusColor: Color {
        isBlown ? .red : .green
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 44, height: 44)
                .background(statusColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.headline)

                Text(formatDate(archivedAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(isBlown ? Color.clear : statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .glassCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.setLocalizedDateFormatFromTemplate("d. MMMM yyyy")
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview("Blown") {
    ArchiveStatusCard(isBlown: true, archivedAt: Date())
        .padding()
}

#Preview("Fully Evolved") {
    ArchiveStatusCard(isBlown: false, archivedAt: Date())
        .padding()
}
#endif
