import SwiftUI

struct CreatePetOverlay: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        Color.clear
            .sheet(isPresented: $coordinator.isShowing) {
                coordinator.dismiss()
            } content: {
                CreatePetMultiStep()
                    .environment(coordinator)
                    .interactiveDismissDisabled()
            }
    }
}

#if DEBUG
#Preview {
    CreatePetOverlay()
        .environment(CreatePetCoordinator())
}
#endif
