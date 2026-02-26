import FamilyControls
import SwiftUI

struct OnboardingAppSelectionStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?

    @State private var selection = FamilyActivitySelection()
    @State private var pickerID = UUID()
    @State private var showPickerSheet = false

    // Animation state
    @State private var showCTA = false
    @State private var showOverview = false
    @State private var showInfo = false

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)
                .padding(.bottom, 24)

            Spacer()

            if !hasSelection && showCTA {
                chooseCTA
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if hasSelection && showOverview {
                overview
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if hasSelection && showInfo {
                info
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            if hasSelection {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.3), value: hasSelection)
        .onAppear { handleAppear() }
        .onChange(of: selection) { _, _ in
            SharedDefaults.saveFamilyActivitySelection(selection)
        }
        .sheet(isPresented: $showPickerSheet, onDismiss: handlePickerDismiss) {
            pickerSheet
        }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 8) {
            Text("The wind doesn't come from everywhere.")
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .foregroundStyle(.primary)

            Text("Only from the apps that pull you in.")
                .font(AppFont.quicksand(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Choose CTA

    private var chooseCTA: some View {
        Button {
            HapticType.impactLight.trigger()
            showPickerSheet = true
        } label: {
            Label("Choose your apps", systemImage: "app.badge.checkmark")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Overview (after selection)

    private var overview: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            LimitedSourcesPreview(
                applicationTokens: Array(selection.applicationTokens),
                categoryTokens: selection.categoryTokens,
                webDomainTokens: selection.webDomainTokens
            )

            Spacer()

            Button {
                HapticType.impactLight.trigger()
                showPickerSheet = true
            } label: {
                Text("Edit")
                    .font(AppFont.quicksand(.subheadline, weight: .medium))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassBackground(cornerRadius: 16)
    }

    // MARK: - Info

    private var info: some View {
        Label {
            Text("You can change your selection once a day.")
        } icon: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .font(AppFont.quicksand(.caption, weight: .medium))
        .foregroundStyle(.secondary)
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Picker Sheet

    private var pickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pickerHeader
                    .zIndex(1)

                FamilyActivityPicker(selection: $selection)
                    .id(pickerID)
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 16)
                        .allowsHitTesting(false)
                    }
            }
            .navigationTitle("Select apps to limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showPickerSheet = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasSelection)
                }
            }
        }
    }

    private var pickerHeader: some View {
        HStack(spacing: 8) {
            if hasSelection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                LimitedSourcesPreview(
                    applicationTokens: Array(selection.applicationTokens),
                    categoryTokens: selection.categoryTokens,
                    webDomainTokens: selection.webDomainTokens
                )
            } else {
                Text("Tap to select apps or categories")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: 20)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: hasSelection)
    }

    // MARK: - Actions

    private func handleAppear() {
        eyesOverride = "neutral"

        if let saved = SharedDefaults.loadFamilyActivitySelection() {
            selection = saved
            pickerID = UUID()
        }

        if skipAnimation || hasSelection {
            showCTA = true
            showOverview = true
            showInfo = true
        } else {
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.easeOut(duration: 0.4)) {
                    showCTA = true
                }
            }
        }
    }

    private func handlePickerDismiss() {
        guard hasSelection else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            showOverview = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeOut(duration: 0.3)) {
                showInfo = true
            }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride in
        OnboardingAppSelectionStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride
        )
    }
}
#endif
