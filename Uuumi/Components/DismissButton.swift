import SwiftUI

struct DismissButtonModifier: ViewModifier {
    let placement: ToolbarItemPlacement
    let action: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: placement) {
                Button {
                    if let action {
                        action()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

extension View {
    func dismissButton(
        placement: ToolbarItemPlacement = .topBarLeading,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(DismissButtonModifier(placement: placement, action: action))
    }
}
