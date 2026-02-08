import SwiftUI

/// Sheet for archiving a fully evolved pet.
/// Shows congratulatory message and confirms permanent archive.
struct SuccessArchiveSheet: View {
    let petName: String
    let themeColor: Color
    var onArchive: () -> Void = {}

    var body: some View {
        ConfirmationSheet(
            navigationTitle: "Archive Pet",
            header: ConfirmationSheetHeader(
                icon: "checkmark.seal.fill",
                iconColor: themeColor,
                title: "\(petName) reached max evolution!",
                subtitle: "Archived pet will be stored in Overview but cannot be restored."
            ),
            actions: [
                ConfirmationSheetAction(
                    icon: "archivebox",
                    title: "Archive",
                    subtitle: "Safely store in Overview",
                    background: .tinted(themeColor),
                    action: onArchive
                )
            ],
            height: 320
        )
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
