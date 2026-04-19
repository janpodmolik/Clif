import SwiftUI

#if DEBUG
/// Adds a floating wrench button on local Debug builds to access TesterView.
/// Completely hidden on TestFlight and App Store builds.
struct TesterOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomLeading) {
                Button {
                    isPresented = true
                } label: {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .opacity(0.6)
                }
                .padding(.leading, 8)
                .padding(.bottom, 100)
            }
            .sheet(isPresented: $isPresented) {
                TesterView()
            }
    }
}
#endif

extension View {
    func testerOverlay(isPresented: Binding<Bool>) -> some View {
        #if DEBUG
        return modifier(TesterOverlayModifier(isPresented: isPresented))
        #else
        return self
        #endif
    }
}
