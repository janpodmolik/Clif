import SwiftUI

struct CoinRewardTag: View {
    let amount: Int
    let isVisible: Bool
    let isSlidingDown: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "u.circle.fill")
                .font(.title3)
            Text("+\(amount)")
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("PremiumGold"), in: Capsule())
        .offset(y: isSlidingDown ? 60 : 0)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.5)
    }
}

#Preview {
    VStack(spacing: 40) {
        CoinRewardTag(amount: 5, isVisible: true, isSlidingDown: false)
        CoinRewardTag(amount: 5, isVisible: true, isSlidingDown: true)
        CoinRewardTag(amount: 2, isVisible: false, isSlidingDown: false)
    }
}
