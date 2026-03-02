import FamilyControls
import SwiftUI

struct OnboardingNamingStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?

    @Environment(PetManager.self) private var petManager

    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // MARK: - Input State

    @State private var petName = ""
    @State private var petPurpose = ""
    @State private var showInput = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case purpose
    }

    // MARK: - Completion

    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()
                .frame(height: 32)

            if showInput {
                nameInput
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            if showButton {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .overlay {
            tapToSkipOverlay
        }
        .animation(.easeOut(duration: 0.3), value: showInput)
        .animation(.easeOut(duration: 0.3), value: showButton)
        .onAppear { handleAppear() }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Every Uuumi deserves a name.")
                Text("What will you call yours?")
                    .font(AppFont.quicksand(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "Every Uuumi deserves a name.",
                    skipRequested: skipped,
                    onCompleted: {
                        Task {
                            if !skipped {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showSecondLine = true }
                        }
                    }
                )

                TypewriterText(
                    text: "What will you call yours?",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                        revealInput()
                    }
                )
                .font(AppFont.quicksand(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
                .opacity(showSecondLine ? 1 : 0)
            }
        }
        .font(AppFont.quicksand(.title2, weight: .semiBold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Input Fields

    private var nameInput: some View {
        VStack(spacing: 16) {
            TextField("e.g. Fern", text: $petName)
                .textFieldStyle(GlassTextFieldStyle())
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .purpose
                }
                .onChange(of: petName) {
                    withAnimation {
                        showButton = isNameValid
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Purpose")
                        .font(AppFont.quicksand(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("(optional)")
                        .font(AppFont.quicksand(.caption, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 4)

                TextField("e.g. Reduce social media", text: $petPurpose)
                    .textFieldStyle(GlassTextFieldStyle())
                    .focused($focusedField, equals: .purpose)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
            }
        }
        .font(AppFont.quicksand(.body, weight: .medium))
        .multilineTextAlignment(.center)
    }

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            createPet()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Tap to Skip

    @ViewBuilder
    private var tapToSkipOverlay: some View {
        if !skipAnimation && !textCompleted {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticType.impactLight.trigger()
                    narrativeBeat += 1
                }
        }
    }

    // MARK: - Actions

    private var isNameValid: Bool {
        !petName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func revealInput() {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation { showInput = true }
            try? await Task.sleep(for: .seconds(0.4))
            focusedField = .name
        }
    }

    private func createPet() {
        let trimmedName = petName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        focusedField = nil

        let settings = SharedDefaults.limitSettings
        let preset = WindPreset(rawValue: settings.defaultWindPresetRaw) ?? .balanced

        var limitedSources: [LimitedSource] = []
        if let selection = SharedDefaults.loadFamilyActivitySelection() {
            limitedSources = LimitedSource.from(selection)
        }

        let trimmedPurpose = petPurpose.trimmingCharacters(in: .whitespaces)

        petManager.create(
            name: trimmedName,
            purpose: trimmedPurpose.isEmpty ? nil : trimmedPurpose,
            preset: preset,
            limitedSources: limitedSources
        )

        onContinue()
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        eyesOverride = "happy"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showInput = true
            showButton = isNameValid
        }
    }
}

// MARK: - Glass Text Field Style

private struct GlassTextFieldStyle: TextFieldStyle {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 14
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Layout.padding)
            .glassBackground(cornerRadius: Layout.cornerRadius)
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride, _ in
        OnboardingNamingStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride
        )
        .environment(PetManager())
    }
}
#endif
