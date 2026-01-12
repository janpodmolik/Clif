import FamilyControls
import ManagedSettings
import SwiftUI

struct PetScreenTimeCarousel: View {
    let activePets: [ActivePet]
    let fallbackStats: WeeklyUsageStats
    var applicationTokens: Set<ApplicationToken> = []
    var categoryTokens: Set<ActivityCategoryToken> = []
    var onPetTap: (ActivePet) -> Void

    @State private var selectedIndex: Int = 0
    @State private var scrollTarget: UUID?

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40

    var body: some View {
        if activePets.isEmpty {
            FallbackScreenTimeCard(
                stats: fallbackStats,
                applicationTokens: applicationTokens,
                categoryTokens: categoryTokens
            )
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 12) {
                carousel

                if activePets.count > 1 {
                    pageIndicators
                }
            }
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(activePets.enumerated()), id: \.element.id) { _, pet in
                    PetScreenTimeCard(pet: pet) {
                        onPetTap(pet)
                    }
                    .frame(width: cardWidth)
                    .id(pet.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollTarget, anchor: .leading)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .onChange(of: scrollTarget) { _, newValue in
            if let newValue, let index = activePets.firstIndex(where: { $0.id == newValue }) {
                selectedIndex = index
            }
        }
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<activePets.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == selectedIndex ? 1.0 : 0.8)
                    .animation(.spring(response: 0.3), value: selectedIndex)
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = index
                            scrollTarget = activePets[index].id
                        }
                    }
            }
        }
    }
}

#Preview("Multiple Pets") {
    PetScreenTimeCarousel(
        activePets: ActivePet.mockList(),
        fallbackStats: .mock(),
        onPetTap: { _ in }
    )
}

#Preview("Single Pet") {
    PetScreenTimeCarousel(
        activePets: [.mock()],
        fallbackStats: .mock(),
        onPetTap: { _ in }
    )
}

#Preview("No Pets (Fallback)") {
    PetScreenTimeCarousel(
        activePets: [],
        fallbackStats: .mock(),
        onPetTap: { _ in }
    )
    .padding()
}
