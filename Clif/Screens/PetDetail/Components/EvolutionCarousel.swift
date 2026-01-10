import SwiftUI

struct EvolutionCarousel: View {
    let currentPhase: Int
    let essence: Essence
    let mood: Mood

    @State private var selectedIndex: Int = 0

    /// Total cards = 1 (origin) + maxPhase (evolution phases)
    private var totalCards: Int { 1 + essence.maxPhases }

    init(currentPhase: Int, essence: Essence, mood: Mood) {
        self.currentPhase = currentPhase
        self.essence = essence
        self.mood = mood
        // Default to current phase card (index 0 = origin, index 1 = phase 1, etc.)
        self._selectedIndex = State(initialValue: currentPhase)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Evolution Path")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            TabView(selection: $selectedIndex) {
                // Origin card (index 0)
                EvolutionOriginCard(essence: essence, mood: mood)
                    .tag(0)

                // Phase cards (index 1 to maxPhase)
                ForEach(1...essence.maxPhases, id: \.self) { phase in
                    EvolutionPhaseCard(
                        phase: phase,
                        isCurrentPhase: phase == currentPhase,
                        isLocked: phase > currentPhase,
                        essence: essence,
                        mood: mood
                    )
                    .tag(phase)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 260)

            // Indicator dots
            HStack(spacing: 8) {
                ForEach(0..<totalCards, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == selectedIndex ? 1.3 : 1.0)
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
    }

    private func dotColor(for index: Int) -> Color {
        if index == 0 {
            // Origin dot - always filled with essence color
            return essence.themeColor
        }
        let phase = index // phase number = index (since origin is 0)
        if phase <= currentPhase {
            return .green
        }
        return Color.secondary.opacity(0.3)
    }
}

// MARK: - Origin Card

struct EvolutionOriginCard: View {
    let essence: Essence
    let mood: Mood

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
        .padding(.horizontal)
    }

    /// Asset name for blob based on mood: "evolutions/blob/happy"
    private var blobAssetName: String {
        "evolutions/blob/\(mood.rawValue)"
    }

    private var originImageView: some View {
        HStack(spacing: 8) {
            // Blob image - try UIImage for namespace support
            if let blobImage = UIImage(named: blobAssetName) {
                Image(uiImage: blobImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                // Fallback placeholder
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.secondary)
                    }
            }

            Text("+")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)

            // Essence image
            if let essenceImage = UIImage(named: essence.assetName) {
                Image(uiImage: essenceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                // Fallback placeholder
                Circle()
                    .fill(essence.themeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(essence.themeColor)
                    }
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(essence.themeColor.opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(essence.themeColor.opacity(0.3), lineWidth: 1)
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
        .padding(.horizontal)
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
        if isCurrentPhase {
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
                    isCurrentPhase
                        ? .regular.tint(essence.themeColor.opacity(0.2))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    if isCurrentPhase {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(essence.themeColor.opacity(0.5), lineWidth: 2)
                    }
                }
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            EvolutionCarousel(
                currentPhase: 2,
                essence: .plant,
                mood: .happy
            )

            EvolutionCarousel(
                currentPhase: 1,
                essence: .plant,
                mood: .sad
            )

            EvolutionCarousel(
                currentPhase: 4,
                essence: .plant,
                mood: .neutral
            )
        }
        .padding()
    }
}
#endif
