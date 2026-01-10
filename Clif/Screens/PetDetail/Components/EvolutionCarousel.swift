import SwiftUI

struct EvolutionCarousel: View {
    let currentPhase: Int
    let essence: Essence
    let mood: Mood

    @State private var selectedIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 180
    private let cardSpacing: CGFloat = 16
    private var maxPhase: Int { essence.maxPhases }

    init(currentPhase: Int, essence: Essence, mood: Mood) {
        self.currentPhase = currentPhase
        self.essence = essence
        self.mood = mood
        self._selectedIndex = State(initialValue: currentPhase - 1)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Evolution Path")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let centerOffset = (totalWidth - cardWidth) / 2

                HStack(spacing: cardSpacing) {
                    ForEach(1...maxPhase, id: \.self) { phase in
                        EvolutionPhaseCard(
                            phase: phase,
                            isCurrentPhase: phase == currentPhase,
                            isLocked: phase > currentPhase,
                            essence: essence,
                            mood: mood
                        )
                        .frame(width: cardWidth)
                        .rotation3DEffect(
                            rotationAngle(for: phase - 1, in: geometry),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                        .scaleEffect(scaleEffect(for: phase - 1))
                        .opacity(opacityEffect(for: phase - 1))
                        .zIndex(phase - 1 == selectedIndex ? 1 : 0)
                    }
                }
                .offset(x: centerOffset + offsetForSelectedIndex)
                .offset(x: dragOffset)
                .gesture(dragGesture)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            }
            .frame(height: 240)

            // Indicator dots
            HStack(spacing: 8) {
                ForEach(0..<maxPhase, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == selectedIndex ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: selectedIndex)
                        .onTapGesture {
                            selectedIndex = index
                        }
                }
            }
        }
        .padding()
        .glassCard()
    }

    private var offsetForSelectedIndex: CGFloat {
        -CGFloat(selectedIndex) * (cardWidth + cardSpacing)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                let predictedOffset = value.predictedEndTranslation.width

                if predictedOffset < -threshold && selectedIndex < maxPhase - 1 {
                    selectedIndex += 1
                } else if predictedOffset > threshold && selectedIndex > 0 {
                    selectedIndex -= 1
                }

                dragOffset = 0
            }
    }

    private func rotationAngle(for index: Int, in geometry: GeometryProxy) -> Angle {
        let offset = CGFloat(index - selectedIndex) + (dragOffset / (cardWidth + cardSpacing))
        let maxRotation: Double = 35
        return .degrees(-offset * maxRotation)
    }

    private func scaleEffect(for index: Int) -> CGFloat {
        let offset = abs(CGFloat(index - selectedIndex) + (dragOffset / (cardWidth + cardSpacing)))
        return max(0.85, 1 - offset * 0.1)
    }

    private func opacityEffect(for index: Int) -> Double {
        let offset = abs(CGFloat(index - selectedIndex) + (dragOffset / (cardWidth + cardSpacing)))
        return max(0.6, 1 - offset * 0.2)
    }

    private func dotColor(for index: Int) -> Color {
        let phase = index + 1
        if phase <= currentPhase {
            return .green
        }
        return Color.secondary.opacity(0.3)
    }
}

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
            // Fallback
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
