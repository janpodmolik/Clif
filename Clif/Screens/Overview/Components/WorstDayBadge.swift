import SwiftUI

struct WorstDayBadge: View {
    let dayName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up")
                .font(.system(size: 10, weight: .bold))
            Text(dayName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.red.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        WorstDayBadge(dayName: "Pá")
        WorstDayBadge(dayName: "Sobota")
    }
    .padding()
}
