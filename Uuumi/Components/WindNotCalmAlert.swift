import SwiftUI

struct WindNotCalmAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert("Wind Must Be Calm", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Reduce wind to 0% before you can use essence or archive your pet.")
            }
    }
}

extension View {
    func windNotCalmAlert(isPresented: Binding<Bool>) -> some View {
        modifier(WindNotCalmAlertModifier(isPresented: isPresented))
    }
}
