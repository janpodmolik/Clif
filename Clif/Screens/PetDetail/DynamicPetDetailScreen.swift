import SwiftUI

struct DynamicPetDetailScreen: View {
    let pet: DynamicPet

    // MARK: - Context
    var showOverviewActions: Bool = false

    // MARK: - Actions
    var onAction: (DynamicPetDetailAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var showEssencePicker = false

    private var mood: Mood {
        pet.isBlown ? .blown : Mood(from: pet.windLevel)
    }

    private var themeColor: Color {
        pet.themeColor
    }

    /// canUseEssence for blob, canEvolve for evolved
    private var canProgress: Bool {
        pet.isBlob ? pet.canUseEssence : pet.canEvolve
    }

    /// daysUntilEssence for blob, daysUntilEvolution for evolved
    private var daysUntilProgress: Int? {
        pet.isBlob ? pet.daysUntilEssence : pet.daysUntilEvolution
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DynamicStatusCard(
                        windProgress: pet.windProgress,
                        windLevel: pet.windLevel,
                        isBlownAway: pet.isBlown,
                        isOnBreak: pet.activeBreak != nil,
                        onStartBreak: { onAction(.startBreak) }
                    )

                    if let activeBreak = pet.activeBreak {
                        BreakStatusCard(
                            activeBreak: activeBreak,
                            currentWindPoints: pet.windPoints,
                            onEndBreak: { onAction(.endBreak) }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showEssencePicker) {
                EssencePickerSheet { essence in
                    pet.applyEssence(essence)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Dynamic Pet Detail") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mock(name: "Fern", phase: 2, windPoints: 45))
        }
}

#Preview("With Active Break") {
    Text("Tap to open")
        .fullScreenCover(isPresented: .constant(true)) {
            DynamicPetDetailScreen(pet: .mockWithBreak())
        }
}
#endif
