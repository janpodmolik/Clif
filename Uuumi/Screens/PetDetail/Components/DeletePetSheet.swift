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
        ConfirmationSheet(
            navigationTitle: "Odstranit peta",
            height: showArchiveOption ? 340 : 280
        ) {
            ConfirmationHeader(
                icon: showArchiveOption ? "questionmark.circle" : "trash.circle",
                iconColor: showArchiveOption ? .orange : .red,
                title: "Co chceš udělat s \(petName)?"
            )

            VStack(spacing: 12) {
                if showArchiveOption {
                    ConfirmationAction(
                        icon: "archivebox",
                        title: "Archivovat",
                        subtitle: "Zachová historii v přehledu"
                    ) {
                        dismiss()
                        onArchive()
                    }
                }

                ConfirmationAction(
                    icon: "trash",
                    title: "Smazat trvale",
                    subtitle: "Odstraní všechna data",
                    foregroundColor: .red,
                    background: .tinted(.red)
                ) {
                    dismiss()
                    onDelete()
                }
            }
        }
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
