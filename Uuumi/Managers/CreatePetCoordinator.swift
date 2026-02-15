import FamilyControls
import SwiftUI

// MARK: - Step Definition

enum CreatePetStep: Int, CaseIterable {
    case appSelection = 0
    case presetSelection = 1
    case petInfo = 2

    var title: String {
        switch self {
        case .appSelection: "Select Apps"
        case .presetSelection: "Configure"
        case .petInfo: "Name Your Pet"
        }
    }

    var canGoBack: Bool {
        self != .appSelection
    }

    var isLast: Bool {
        self == .petInfo
    }
}

// MARK: - Drag State

struct BlobDragState: Equatable {
    var isDragging = false
    var isReturning = false
    var isOnTarget = false
    var dragLocation: CGPoint = .zero
    var dragVelocity: CGSize = .zero
    var startLocation: CGPoint = .zero
    var snapTarget: CGPoint = .zero
}

// MARK: - Coordinator

@Observable
final class CreatePetCoordinator {
    // MARK: - Presentation State

    var isShowing = false
    var isDropping = false
    var dismissDragOffset: CGFloat = 0

    // MARK: - Step Navigation

    var currentStep: CreatePetStep = .appSelection

    // MARK: - Collected Data

    var selectedApps = FamilyActivitySelection()
    var preset: WindPreset = .balanced
    var petName: String = ""
    var petPurpose: String = ""
    var saveAsMyApps: Bool = false

    // MARK: - Drag State (Step 3)

    var dragState = BlobDragState()
    var petDropFrame: CGRect?
    var petHeight: CGFloat = 0

    // MARK: - Callbacks

    private var onComplete: ((Pet) -> Void)?
    private var cleanupWorkItem: DispatchWorkItem?

    // MARK: - Computed

    var canProceed: Bool {
        switch currentStep {
        case .appSelection:
            !selectedApps.applicationTokens.isEmpty ||
            !selectedApps.categoryTokens.isEmpty ||
            !selectedApps.webDomainTokens.isEmpty
        case .presetSelection:
            true
        case .petInfo:
            !petName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var totalSteps: Int {
        CreatePetStep.allCases.count
    }

    // MARK: - Public API

    func show(onComplete: @escaping (Pet) -> Void) {
        cleanupWorkItem?.cancel()
        cleanupWorkItem = nil

        resetWizardState()
        self.onComplete = onComplete
        isShowing = true
    }

    #if DEBUG
    /// Skips directly to drop phase with mock data for faster testing
    func showDropOnly(onComplete: @escaping (Pet) -> Void) {
        cleanupWorkItem?.cancel()
        cleanupWorkItem = nil

        resetWizardState()
        self.onComplete = onComplete

        // Pre-fill with mock data
        preset = .balanced
        petName = "Debug Pet"
        currentStep = .petInfo

        // Go straight to drop phase
        isDropping = true
    }
    #endif

    func dismiss() {
        isShowing = false
        isDropping = false

        cleanupWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.resetWizardState()
            self?.cleanupWorkItem = nil
        }
        cleanupWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
    }

    func nextStep() {
        guard canProceed else { return }
        guard let nextIndex = CreatePetStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = nextIndex
        }
    }

    func previousStep() {
        guard currentStep.canGoBack else { return }
        guard let prevIndex = CreatePetStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = prevIndex
        }
    }

    // MARK: - Drop Phase Transitions

    func proceedToDrop() {
        guard canProceed, currentStep.isLast else { return }

        // First activate drop mode (keeps isInCreationMode true)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isDropping = true
        }

        // Then dismiss wizard sheet after overlap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                self.isShowing = false
            }
        }
    }

    func backFromDrop() {
        // First show wizard sheet (keeps isInCreationMode true)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isShowing = true
        }

        // Then dismiss drop overlay after overlap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                self.isDropping = false
            }
        }
    }

    func handleBlobDrop(petManager: PetManager, analyticsManager: AnalyticsManager) {
        // Guard: cannot create if pet already exists
        guard !petManager.hasPet else {
            dismiss()
            return
        }

        let limitedSources = LimitedSource.from(selectedApps)

        guard let pet = petManager.create(
            name: petName,
            purpose: petPurpose.isEmpty ? nil : petPurpose,
            preset: preset,
            limitedSources: limitedSources
        ) else {
            dismiss()
            return
        }

        // Persist selection for pre-populating the picker on edit
        SharedDefaults.saveFamilyActivitySelection(selectedApps)

        // Save as "Moje aplikace" preset if user toggled the checkbox
        if saveAsMyApps {
            SharedDefaults.saveMyAppsSelection(selectedApps)
        }

        // Apply preset (locks it for today, starts monitoring, resets wind)
        ScreenTimeManager.shared.applyDailyPreset(preset, for: pet)

        analyticsManager.send(.petCreated(essenceType: "blob"))
        analyticsManager.send(.presetSelected(presetName: preset.rawValue, context: .creation))

        onComplete?(pet)
        dismiss()
    }

    // MARK: - Private

    /// Resets wizard data when starting a new pet creation flow.
    /// Does NOT reset petDropFrame since it's managed by HomeScreen.
    private func resetWizardState() {
        currentStep = .appSelection
        selectedApps = FamilyActivitySelection()
        preset = .balanced
        petName = ""
        petPurpose = ""
        saveAsMyApps = false
        dragState = BlobDragState()
        dismissDragOffset = 0
        onComplete = nil
    }

}
