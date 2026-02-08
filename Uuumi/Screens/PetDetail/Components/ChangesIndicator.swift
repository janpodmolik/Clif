import SwiftUI

/// Box indicator showing used/remaining changes out of a total.
/// Boxes with X = used, empty boxes = remaining.
struct ChangesIndicator: View {
    let used: Int
    let total: Int

    private let boxSize: CGFloat = 28
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< total, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: boxSize, height: boxSize)

                    if index < used {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
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
