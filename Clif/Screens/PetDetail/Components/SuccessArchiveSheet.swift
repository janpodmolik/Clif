import SwiftUI

/// Sheet for archiving a fully evolved pet.
/// Shows congratulatory message and confirms permanent archive.
struct SuccessArchiveSheet: View {
    let petName: String
    let themeColor: Color
    var onArchive: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                archiveButton
                Spacer()
            }
            .padding(24)
            .navigationTitle("Archive Pet")
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
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(themeColor)

            Text("\(petName) reached max evolution!")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Archived pet will be stored in Overview but cannot be restored.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var archiveButton: some View {
        Button {
            dismiss()
            onArchive()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "archivebox")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Archive")
                        .font(.headline)
                    Text("Safely store in Overview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Success Archive") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            SuccessArchiveSheet(
                petName: "Fern",
                themeColor: .green,
                onArchive: { print("Archive") }
            )
        }
}
#endif
