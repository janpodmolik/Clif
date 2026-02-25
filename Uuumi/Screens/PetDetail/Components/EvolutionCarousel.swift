import SwiftUI

struct EvolutionCarousel<Pet: PetEvolvable>: View {
    let pet: Pet
    var isBlownAway: Bool = false
    var canUseEssence: Bool = false
    var showCurrentBadge: Bool = true
    var showBlobStatusBadge: Bool = true

    @State private var selectedIndex: Int = 0
    @State private var scrollTarget: Int?
    private let cardWidth: CGFloat = 230
    private let cardHeight: CGFloat = 240

    // MARK: - Convenience from PetEvolvable

    private var currentPhase: Int { pet.currentPhase }
    private var essence: Essence? { pet.essence }
    private var isBlob: Bool { pet.isBlob }
    private var themeColor: Color { pet.themeColor }
    private var evolutionPath: EvolutionPath? { pet.evolutionPath }

    /// Total cards = 1 for blob, or 1 (origin) + maxPhase (evolution phases) for evolved
    private var totalCards: Int {
        guard let evolutionPath else { return 1 }
        return 1 + evolutionPath.maxPhases
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Evolution Path")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 20)

            carousel

            // Indicator dots (only show if more than 1 card)
            if totalCards > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<totalCards, id: \.self) { index in
                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == selectedIndex ? 1.5 : 1.0)
                            .animation(.spring(response: 0.3), value: selectedIndex)
                            .onTapGesture {
                                withAnimation {
                                    scrollTarget = index
                                }
                            }
                    }
                }
                .padding(.top)
                .padding(.bottom, 20)
            } else {
                Spacer().frame(height: 20)
            }
        }
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

    @ViewBuilder
    private var carousel: some View {
        if isBlob {
            // Single centered card for blob - no scrolling needed
            cardView(for: 0)
                .frame(width: cardWidth, height: cardHeight)
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 12,
                    x: 0,
                    y: 10
                )
                .frame(maxWidth: .infinity)
                .frame(height: cardHeight + 24)
        } else {
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
                .scrollClipDisabled()
                .padding(.top, 4)
                .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
                .frame(height: cardHeight + 24)
            }
            .frame(height: cardHeight + 24)
        }
    }

    @ViewBuilder
    private func cardView(for index: Int) -> some View {
        if isBlob {
            // Blob-only card (no essence yet)
            BlobOnlyCard(isBlownAway: isBlownAway, canUseEssence: canUseEssence, showStatusBadge: showBlobStatusBadge)
        } else if index == 0, let essence, let path = evolutionPath {
            EvolutionOriginCard(essence: essence, path: path, isBlownAway: isBlownAway, themeColor: themeColor)
        } else if let path = evolutionPath {
            EvolutionPhaseCard(
                phase: index,
                isCurrentPhase: index == currentPhase,
                isLocked: index > currentPhase,
                evolutionPath: path,
                isBlownAway: isBlownAway,
                themeColor: themeColor,
                showCurrentBadge: showCurrentBadge
            )
        }
    }

    private func dotColor(for index: Int) -> Color {
        let phase = index // phase number = index (origin is 0, phases are 1+)

        // All unlocked phases (including origin) use themeColor
        if phase <= currentPhase {
            return themeColor
        }

        // Locked phases
        return Color.secondary.opacity(0.3)
    }
}

// MARK: - Blob Only Card

struct BlobOnlyCard: View {
    var isBlownAway: Bool = false
    var canUseEssence: Bool = false
    var showStatusBadge: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            PetImage(Blob.shared, isBlownAway: isBlownAway)
                .frame(height: 140)

            Text("Blob")
                .font(.subheadline.weight(.semibold))

            if showStatusBadge {
                statusBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if canUseEssence {
            Text("Ready for Essence")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green, in: Capsule())
        } else {
            Text("Awaiting essence")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.05))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Origin Card

struct EvolutionOriginCard: View {
    let essence: Essence
    let path: EvolutionPath
    var isBlownAway: Bool = false
    var themeColor: Color = .green

    var body: some View {
        VStack(spacing: 12) {
            originImageView
                .frame(height: 140)

            Text("Origin")
                .font(.subheadline.weight(.semibold))

            Text(path.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var originImageView: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let blobSize = totalWidth * 0.45  // ~2/3 of content
            let essenceSize = totalWidth * 0.25  // ~1/3 of content

            HStack(spacing: 6) {
                // Blob image (2/3)
                PetImage(Blob.shared, isBlownAway: isBlownAway)
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
    let evolutionPath: EvolutionPath
    var isBlownAway: Bool = false
    var themeColor: Color = .green
    var showCurrentBadge: Bool = true

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
        } else if let evolution = evolutionPath.phase(at: phase) {
            PetImage(evolution, isBlownAway: isBlownAway)
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
        if isCurrentPhase && showCurrentBadge {
            Text("Current")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(themeColor, in: Capsule())
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

    private var cardTintOpacity: Double {
        if isLocked { return 0 }
        return isCurrentPhase ? 0.15 : 0.08
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isLocked ? .regular : .regular.tint(cardTintColor.opacity(cardTintOpacity)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(isLocked ? Color.clear : cardTintColor.opacity(cardTintOpacity))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    if !isLocked {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(cardTintColor.opacity(isCurrentPhase ? 0.25 : 0.15), lineWidth: 1)
                    }
                }
        }
    }

    private var cardTintColor: Color {
        themeColor
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Blob (no essence)").font(.caption)
            EvolutionCarousel(
                pet: ArchivedPet.mockBlob()
            )

            Text("Blob - Ready for Essence").font(.caption)
            EvolutionCarousel(
                pet: ArchivedPet.mockBlob(),
                canUseEssence: true
            )

            Text("With essence - Phase 2").font(.caption)
            EvolutionCarousel(
                pet: ArchivedPet.mock(phase: 2)
            )

            Text("Blown away at Phase 1").font(.caption)
            EvolutionCarousel(
                pet: ArchivedPet.mock(phase: 1, archiveReason: .blown),
                isBlownAway: true
            )

            Text("Fully evolved - Phase 4").font(.caption)
            EvolutionCarousel(
                pet: ArchivedPet.mock(phase: 4)
            )
        }
        .padding()
    }
}
#endif
