import SwiftUI

struct HistoryIslandsCarousel: View {
    @Environment(\.colorScheme) private var colorScheme

    let pets: [ArchivedPet]
    let onSelect: (ArchivedPet) -> Void

    private let islandSpacing: CGFloat = 50
    private let carouselHeight: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Hall of Fame")
                    .font(.headline)
            }

            if pets.isEmpty {
                emptyState
            } else {
                carouselContent
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "leaf.arrow.triangle.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("Zatím žádný dokončený pet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .frame(height: carouselHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var carouselContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: islandSpacing) {
                ForEach(pets) { pet in
                    HistoryIslandView(pet: pet, height: carouselHeight) {
                        onSelect(pet)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: carouselHeight)
        .background {
            Group {
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack {
        HistoryIslandsCarousel(
            pets: ArchivedPet.mockList().filter { $0.isCompleted },
            onSelect: { _ in }
        )

        HistoryIslandsCarousel(pets: [], onSelect: { _ in })
    }
    .padding()
}
