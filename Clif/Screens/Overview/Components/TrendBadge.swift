import SwiftUI

struct TrendBadge: View {
    let percentage: Int

    private var isWorse: Bool { percentage > 0 }
    private var color: Color { isWorse ? .red : .green }
    private var icon: String { isWorse ? "arrow.up" : "arrow.down" }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text("\(abs(percentage))%")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        TrendBadge(percentage: -15)
        TrendBadge(percentage: 23)
        TrendBadge(percentage: 0)
    }
    .padding()
}
