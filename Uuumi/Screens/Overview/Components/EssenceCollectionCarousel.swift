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
                pageDots
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
                Text("Žádné essence k zobrazení")
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
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    EssenceCard(record: record, height: cardHeight)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap?(record) }
                        .containerRelativeFrame(.horizontal)
                        .frame(height: cardHeight)
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
        .frame(height: cardHeight)
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                Circle()
                    .fill(dotColor(for: record, at: index))
                    .frame(width: 8, height: 8)
                    .scaleEffect((scrollTarget ?? 0) == index ? 1.5 : 1.0)
                    .animation(.spring(response: 0.3), value: scrollTarget)
                    .onTapGesture {
                        withAnimation {
                            scrollTarget = index
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dotColor(for record: EssenceRecord, at index: Int) -> Color {
        let isSelected = (scrollTarget ?? 0) == index
        return isSelected ? record.evolutionPath.themeColor : record.evolutionPath.themeColor.opacity(0.35)
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
                record.evolutionPath.themeColor.opacity(0.15)
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
        let color = record.evolutionPath.themeColor

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
        let color = record.evolutionPath.themeColor
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
