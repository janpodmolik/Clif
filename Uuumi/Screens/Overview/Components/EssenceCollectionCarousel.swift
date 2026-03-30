import SwiftUI

// MARK: - Data Model

struct EssenceRecord: Identifiable, Hashable {
    let id: String
    let essence: Essence
    let bestPhase: Int?
    let petCount: Int

    var evolutionPath: EvolutionPath { .path(for: essence) }
}

// MARK: - Carousel

struct EssenceCollectionCarousel: View {
    let records: [EssenceRecord]
    var onTap: ((EssenceRecord) -> Void)?

    @State private var scrollTarget: Int? = 0
    @State private var selectedIndex: Int = 0

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Essence Collection")
                .font(.title3)
                .fontWeight(.semibold)

            if records.isEmpty {
                emptyState
            } else {
                carousel
                if records.count > 1 {
                    pageDots
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No essences to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .frame(height: cardHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Carousel

    private var carousel: some View {
        Group {
            if records.count == 1, let record = records.first {
                singleCard(record)
            } else {
                multiCardCarousel
            }
        }
    }

    private func singleCard(_ record: EssenceRecord) -> some View {
        EssenceCard(record: record, height: cardHeight)
            .contentShape(Rectangle())
            .onTapGesture { onTap?(record) }
            .frame(width: cardWidth, height: cardHeight)
            .shadow(
                color: .black.opacity(0.12),
                radius: 12,
                x: 0,
                y: 10
            )
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight + 24)
    }

    private var multiCardCarousel: some View {
        GeometryReader { proxy in
            let horizontalInset = max(0, (proxy.size.width - cardWidth) / 2)
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        EssenceCard(record: record, height: cardHeight)
                            .contentShape(Rectangle())
                            .onTapGesture { onTap?(record) }
                            .frame(width: cardWidth, height: cardHeight)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .rotation3DEffect(
                                        .degrees(phase.value * -32),
                                        axis: (x: 0, y: 1, z: 0),
                                        perspective: 0.7
                                    )
                                    .scaleEffect(1 - abs(phase.value) * 0.18)
                                    .opacity(1 - abs(phase.value) * 0.35)
                                    .offset(y: abs(phase.value) * 18)
                            }
                            .shadow(
                                color: .black.opacity(0.12),
                                radius: 12,
                                x: 0,
                                y: 10
                            )
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollTarget, anchor: .center)
            .defaultScrollAnchor(.center)
            .scrollClipDisabled()
            .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
            .frame(height: cardHeight + 24)
        }
        .frame(height: cardHeight + 24)
        .onChange(of: scrollTarget) { _, newValue in
            if let newValue {
                selectedIndex = newValue
            }
        }
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(Array(records.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(selectedIndex == index ? Color.green : Color.green.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .scaleEffect(selectedIndex == index ? 1.5 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedIndex)
                    .onTapGesture {
                        withAnimation {
                            scrollTarget = index
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Essence Card

private struct EssenceCard: View {
    let record: EssenceRecord
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            unlockedBackground

            petImage
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .padding(.bottom, 96)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            essenceBadge

            VStack(spacing: 0) {
                Color.green.opacity(0.15)
                    .frame(height: 1)

                VStack(spacing: 6) {
                    Text(record.evolutionPath.displayName)
                        .font(.headline)

                    progressionDots

                    if record.petCount > 0 {
                        Text(record.petCount == 1 ? "1 pet" : "\(record.petCount) pets")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
            .background(
                .ultraThinMaterial,
                in: UnevenRoundedRectangle(
                    bottomLeadingRadius: 20, bottomTrailingRadius: 20
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var essenceBadge: some View {
        Image(record.essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
    }

    private var cardScale: CGFloat {
        guard let phase = record.bestPhase,
              let evolutionPhase = record.evolutionPath.phase(at: phase) else {
            return 0.7
        }
        let normalized = (evolutionPhase.displayScale - 0.95) / (1.40 - 0.95)
        return 0.7 + normalized * 0.25
    }

    @ViewBuilder
    private var petImage: some View {
        if let phase = record.bestPhase,
           let evolutionPhase = record.evolutionPath.phase(at: phase) {
            PetImage(evolutionPhase)
                .scaleEffect(cardScale)
        } else {
            Image(record.essence.assetName)
                .resizable()
                .scaledToFit()
                .scaleEffect(0.7)
        }
    }

    private var progressionDots: some View {
        let maxPhases = record.evolutionPath.maxPhases
        let reached = record.bestPhase ?? 0
        let color = Color.green

        return HStack(spacing: 6) {
            ForEach(1...maxPhases, id: \.self) { phase in
                Circle()
                    .fill(phase <= reached ? color : color.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var unlockedBackground: some View {
        let color = Color.green
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(color.opacity(0.12)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                }
        }
    }

}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            EssenceCollectionCarousel(records: [
                EssenceRecord(id: "plant", essence: .plant, bestPhase: 4, petCount: 3),
            ])

            EssenceCollectionCarousel(records: [
                EssenceRecord(id: "plant", essence: .plant, bestPhase: 2, petCount: 1),
            ])

            EssenceCollectionCarousel(records: [])
        }
        .padding()
    }
}
