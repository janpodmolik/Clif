import SwiftUI

struct EvolutionCarousel: View {
    let currentPhase: Int
    let essence: Essence
    let mood: Mood
    var isBlownAway: Bool = false
    var themeColor: Color = .green

    @State private var selectedIndex: Int = 0
    @State private var scrollTarget: Int?
    private let cardWidth: CGFloat = 230
    private let cardHeight: CGFloat = 240

    /// Total cards = 1 (origin) + maxPhase (evolution phases)
    private var totalCards: Int { 1 + essence.maxPhases }

    var body: some View {
        VStack(spacing: 16) {
            Text("Evolution Path")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 10)

            carousel

            // Indicator dots
            HStack(spacing: 8) {
                ForEach(0..<totalCards, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == selectedIndex ? 1.5 : 1.0)
                        .animation(.spring(response: 0.3), value: selectedIndex)
                        .onTapGesture {
                            withAnimation {
                                selectedIndex = index
                            }
                        }
                }
            }
            .padding(.bottom)
        }
        .glassCard()
        .task(id: currentPhase) {
            selectedIndex = currentPhase
            // Small delay to ensure ScrollView is ready
            try? await Task.sleep(for: .milliseconds(50))
            scrollTarget = currentPhase
        }
        .onChange(of: scrollTarget) { _, newValue in
            if let newValue {
                selectedIndex = newValue
            }
        }
    }

    private var carousel: some View {
        GeometryReader { proxy in
            let horizontalInset = max(0, (proxy.size.width - cardWidth) / 2)
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(0..<totalCards, id: \.self) { index in
                        cardView(for: index)
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
            .padding(.top, 4)
            .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
            .frame(height: cardHeight + 24)
        }
        .frame(height: cardHeight + 24)
    }

    @ViewBuilder
    private func cardView(for index: Int) -> some View {
        if index == 0 {
            EvolutionOriginCard(essence: essence, mood: mood, themeColor: themeColor)
        } else {
            EvolutionPhaseCard(
                phase: index,
                isCurrentPhase: index == currentPhase,
                isLocked: index > currentPhase,
                essence: essence,
                mood: mood,
                isBlownAway: isBlownAway,
                themeColor: themeColor
            )
        }
    }

    private func dotColor(for index: Int) -> Color {
        let phase = index // phase number = index (origin is 0, phases are 1+)

        // Current phase when blown away = red
        if phase == currentPhase && isBlownAway {
            return .red
        }

        // All unlocked phases (including origin) use themeColor
        if phase <= currentPhase {
            return themeColor
        }

        // Locked phases
        return Color.secondary.opacity(0.3)
    }
}

// MARK: - Origin Card

struct EvolutionOriginCard: View {
    let essence: Essence
    let mood: Mood
    var themeColor: Color = .green

    var body: some View {
        VStack(spacing: 12) {
            originImageView
                .frame(height: 140)

            Text("Origin")
                .font(.subheadline.weight(.semibold))

            Text(essence.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var blobAssetName: String {
        Blob.shared.assetName(for: mood)
    }

    private var originImageView: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let blobSize = totalWidth * 0.45  // ~2/3 of content
            let essenceSize = totalWidth * 0.25  // ~1/3 of content

            HStack(spacing: 6) {
                // Blob image (2/3)
                Image(blobAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: blobSize, height: blobSize)

                Text("+")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)

                // Essence image (1/3)
                Image(essence.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: essenceSize, height: essenceSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(themeColor.opacity(0.08)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColor.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(themeColor.opacity(0.15), lineWidth: 1)
                }
        }
    }
}

// MARK: - Phase Card

struct EvolutionPhaseCard: View {
    let phase: Int
    let isCurrentPhase: Bool
    let isLocked: Bool
    let essence: Essence
    let mood: Mood
    var isBlownAway: Bool = false
    var themeColor: Color = .green

    var body: some View {
        VStack(spacing: 12) {
            petImageView
                .frame(height: 140)

            phaseLabel

            statusBadge
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    @ViewBuilder
    private var petImageView: some View {
        if isLocked {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))

                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        } else if let evolution = essence.phase(at: phase) {
            Image(evolution.assetName(for: mood))
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        }
    }

    private var phaseLabel: some View {
        Text("Phase \(phase)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isLocked ? .secondary : .primary)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isBlownAway && isCurrentPhase {
            Text("Blown")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red, in: Capsule())
        } else if isCurrentPhase {
            Text("Current")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green, in: Capsule())
        } else if isLocked {
            Text("Locked")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            Text("Completed")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isLocked ? .regular : .regular.tint(cardTintColor.opacity(0.08)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(isLocked ? Color.clear : cardTintColor.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    if !isLocked {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(cardTintColor.opacity(0.15), lineWidth: 1)
                    }
                }
        }
    }

    private var cardTintColor: Color {
        if isCurrentPhase && isBlownAway {
            return .red
        }
        return themeColor
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            EvolutionCarousel(
                currentPhase: 2,
                essence: .plant,
                mood: .happy,
                themeColor: .green
            )

            EvolutionCarousel(
                currentPhase: 1,
                essence: .plant,
                mood: .sad,
                isBlownAway: true,
                themeColor: .green
            )

            EvolutionCarousel(
                currentPhase: 4,
                essence: .plant,
                mood: .neutral,
                themeColor: .green
            )
        }
        .padding()
    }
}
#endif
