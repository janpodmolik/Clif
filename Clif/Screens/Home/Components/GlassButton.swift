import SwiftUI

struct GlassButton: View {
    let systemImage: String
    let action: () -> Void

    private let size: CGFloat = 56

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .circle)
        } else {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: .circle)
        }
    }
}
