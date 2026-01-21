import SwiftUI

struct CircleButton: View {
    let icon: String
    let action: () -> Void

    private let size: CGFloat = 44

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        } else {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: .circle)
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        CircleButton(icon: "chevron.left") { }
        CircleButton(icon: "xmark") { }
    }
    .padding()
}
#endif
