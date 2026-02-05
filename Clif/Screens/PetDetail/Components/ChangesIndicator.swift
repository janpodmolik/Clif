import SwiftUI

/// Dot indicator showing used/remaining changes out of a total.
/// Filled dots = used, empty dots = remaining.
struct ChangesIndicator: View {
    let used: Int
    let total: Int

    private let dotSize: CGFloat = 8
    private let spacing: CGFloat = 5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < used ? Color(.label) : Color.gray.opacity(0.3))
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        ChangesIndicator(used: 0, total: 3)
        ChangesIndicator(used: 1, total: 3)
        ChangesIndicator(used: 2, total: 3)
        ChangesIndicator(used: 3, total: 3)
    }
    .padding()
}
#endif
