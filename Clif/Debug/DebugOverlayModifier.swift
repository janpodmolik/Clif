#if DEBUG
import SwiftUI

struct DebugOverlayModifier: ViewModifier {
    @Environment(PetManager.self) private var petManager

    @State
    private var showDebugView = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                VStack {
                    Spacer()
                    Button {
                        showDebugView = true
                    } label: {
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 50)
                }
                .fullScreenCover(isPresented: $showDebugView) {
                    DebugView()
                        .environment(petManager)
                }
            }
    }
}
#endif
