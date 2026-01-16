import SwiftUI

struct HistoryIslandView: View {
    let pet: ArchivedDailyPet
    let height: CGFloat
    let onTap: () -> Void

    // Animation state
    @State private var movementTriggerTime: TimeInterval = -1
    @State private var currentMovementType: TapAnimationType = .none
    @State private var currentMovementConfig: TapConfig = .none
    @State private var randomMovementTimer: Timer?

    // Random phase offset for breathing desync (0-2.5s = one full breath cycle)
    private let idlePhaseOffset: TimeInterval = .random(in: 0...2.5)

    // Scale factor for enlarging the island (pet will be more visible)
    private let scaleFactor: CGFloat = 2.5
    // How much of the bottom to clip (0.35 = 35%)
    private let bottomClipFraction: CGFloat = 0.35

    // Base dimensions (before scaling)
    private var baseIslandHeight: CGFloat { height * 0.4 }
    private var basePetHeight: CGFloat { height * 0.1 }

    // Scaled dimensions
    private var scaledIslandHeight: CGFloat { baseIslandHeight * scaleFactor }
    private var scaledPetHeight: CGFloat { basePetHeight * scaleFactor }
    private var petOffset: CGFloat { -scaledPetHeight * 1.2 }

    // Offset to move content up so pet stays visible after clipping
    private var contentOffset: CGFloat { scaledIslandHeight * bottomClipFraction }


    private var idleConfig: IdleConfig {
        pet.phase?.idleConfig ?? .default
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
                        .frame(maxHeight: scaledIslandHeight)
                        .overlay(alignment: .top) {
                            Image("grass")
                                .resizable()
                                .scaledToFit()
                        }

                    // Pet positioned on top of grass
                    Image(pet.assetName(for: .happy))
                        .resizable()
                        .scaledToFit()
                        .frame(height: scaledPetHeight)
                        .petAnimation(
                            intensity: 0,
                            tapTime: movementTriggerTime,
                            tapType: currentMovementType,
                            tapConfig: currentMovementConfig,
                            idleConfig: idleConfig,
                            idlePhaseOffset: idlePhaseOffset
                        )
                        .scaleEffect(pet.displayScale, anchor: .bottom)
                        .padding(.top, scaledPetHeight * 0.6)
                        .offset(y: petOffset)
                }
                .offset(y: contentOffset)
                .overlay(alignment: .bottom) {
                    labelsStack
                        .offset(y: -8)
                }
            }
            .frame(height: height, alignment: .bottom)
            .clipped()
        }
        .buttonStyle(.plain)
        .onAppear {
            scheduleRandomMovement()
        }
        .onDisappear {
            randomMovementTimer?.invalidate()
        }
    }

    private var labelsStack: some View {
        VStack(spacing: 4) {
            // Name
            Text(pet.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // Purpose (if available)
            if let purpose = pet.purpose {
                Text(purpose)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Date
            Text(pet.archivedAt, format: .dateTime.day().month(.abbreviated))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 8))
    } 

    // MARK: - Random Movement

    private func scheduleRandomMovement() {
        let delay = Double.random(in: 3...8)
        randomMovementTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            triggerRandomMovement()
            scheduleRandomMovement()
        }
    }

    private func triggerRandomMovement() {
        let movementType = [TapAnimationType.wiggle, .squeeze, .jiggle, .bounce].randomElement() ?? .wiggle
        currentMovementType = movementType
        currentMovementConfig = pet.phase?.tapConfig(for: movementType) ?? .default(for: movementType)
        movementTriggerTime = Date().timeIntervalSinceReferenceDate
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
