import SwiftUI

/// Sheet for deleting or archiving a pet.
/// Shows archive option for active pets, delete-only for archived pets.
struct DeletePetSheet: View {
    let petName: String
    let showArchiveOption: Bool
    var onArchive: () -> Void = {}
    var onDelete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 12) {
                    if showArchiveOption {
                        archiveButton
                    }
                    deleteButton
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Odstranit peta")
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
        .presentationDetents([.height(showArchiveOption ? 340 : 280)])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: showArchiveOption ? "questionmark.circle" : "trash.circle")
                .font(.system(size: 48))
                .foregroundStyle(showArchiveOption ? .orange : .red)

            Text("Co chceš udělat s \(petName)?")
                .font(.headline)
                .multilineTextAlignment(.center)
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
                    Text("Archivovat")
                        .font(.headline)
                    Text("Zachová historii v přehledu")
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
    }

    private var deleteButton: some View {
        Button {
            dismiss()
            onDelete()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smazat trvale")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("Odstraní všechna data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Active Pet (with archive)") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            DeletePetSheet(
                petName: "Fern",
                showArchiveOption: true,
                onArchive: { print("Archive") },
                onDelete: { print("Delete") }
            )
        }
}

#Preview("Archived Pet (delete only)") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            DeletePetSheet(
                petName: "Storm",
                showArchiveOption: false,
                onDelete: { print("Delete") }
            )
        }
}
#endif
