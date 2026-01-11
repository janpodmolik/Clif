import SwiftUI

struct HistoryIslandView: View {
    let pet: ArchivedPet
    let height: CGFloat
    let onTap: () -> Void

    @State private var isBreathing = false

    // Poměry podle FloatingIslandView: island 60%, pet 10% výšky
    private var islandHeight: CGFloat { height * 0.6 }
    private var petHeight: CGFloat { height * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    private var petAssetName: String {
        if let evolution = pet.essence.phase(at: pet.finalPhase) {
            return evolution.assetName(for: .happy)
        }
        return pet.essence.assetName
    }

    private var displayScale: CGFloat {
        pet.essence.phase(at: pet.finalPhase)?.displayScale ?? 1.0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    // Rock with grass overlay (base layer)
                    Image("rock")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: islandHeight)
                        .overlay(alignment: .top) {
                            Image("grass")
                                .resizable()
                                .scaledToFit()
                        }

                    // Pet positioned on top of grass
                    ZStack {
                        Image(petAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: petHeight)
                            .scaleEffect(displayScale, anchor: .bottom)
                            .scaleEffect(isBreathing ? 1.02 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                                value: isBreathing
                            )
                    }
                    .padding(.top, petHeight * 0.6)
                    .offset(y: petOffset)
                }
                .overlay(alignment: .bottom) {
                    nameLabel
                        .offset(y: -8)
                }
            }
            .frame(height: height, alignment: .bottom)
        }
        .buttonStyle(.plain)
        .onAppear {
            isBreathing = true
        }
    }

    private var nameLabel: some View {
        Text(pet.name)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview("Single Island") {
    ZStack {
        DayBackgroundView()
        HistoryIslandView(pet: .mock(name: "Fern", phase: 4), height: 220) { }
    }
    .frame(height: 220)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .padding()
}

#Preview("Phase 1") {
    ZStack {
        DayBackgroundView()
        HistoryIslandView(pet: .mock(name: "Sprout", phase: 1), height: 220) { }
    }
    .frame(height: 220)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .padding()
}
