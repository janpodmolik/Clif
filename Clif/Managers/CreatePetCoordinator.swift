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
    var isSnapped = false
    var dragLocation: CGPoint = .zero
    var dragVelocity: CGSize = .zero
    var startLocation: CGPoint = .zero
    var snapTargetCenter: CGPoint = .zero
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

    // MARK: - Drag State (Step 3)

    var dragState = BlobDragState()
    var petDropFrame: CGRect?

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

        self.onComplete = onComplete
        resetWizardState()
        isShowing = true
    }

    #if DEBUG
    /// Skips directly to drop phase with mock data for faster testing
    func showDropOnly(onComplete: @escaping (Pet) -> Void) {
        cleanupWorkItem?.cancel()
        cleanupWorkItem = nil

        self.onComplete = onComplete
        resetWizardState()

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

    func handleBlobDrop(petManager: PetManager) {
        // Guard: cannot create if pet already exists
        guard !petManager.hasPet else {
            dismiss()
            return
        }

        let limitedSources = createLimitedSources(from: selectedApps)

        guard let pet = petManager.create(
            name: petName,
            purpose: petPurpose.isEmpty ? nil : petPurpose,
            preset: preset,
            limitedSources: limitedSources
        ) else {
            dismiss()
            return
        }

        // Log preset selection for analytics
        SnapshotLogging.logPresetSelected(
            petId: pet.id,
            windPoints: 0,
            preset: preset
        )

        // Start monitoring
        let limitSeconds = Int(preset.minutesToBlowAway * 60)
        let fallRatePerSecond = preset.fallRate / 60.0

        // Initialize wind state for new pet
        SharedDefaults.resetWindState()
        SharedDefaults.monitoredFallRate = fallRatePerSecond

        #if DEBUG
        print("[CreatePet] Starting monitoring - limit: \(limitSeconds)s")
        #endif

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            limitedSources: limitedSources
        )

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
        dragState = BlobDragState()
        dismissDragOffset = 0
        onComplete = nil
    }

    private func createLimitedSources(from selection: FamilyActivitySelection) -> [LimitedSource] {
        var sources: [LimitedSource] = []

        for token in selection.applicationTokens {
            let appSource = AppSource(
                displayName: "App",
                applicationToken: token
            )
            sources.append(.app(appSource))
        }

        for token in selection.categoryTokens {
            let catSource = CategorySource(
                displayName: "Category",
                categoryToken: token
            )
            sources.append(.category(catSource))
        }

        for token in selection.webDomainTokens {
            let webSource = WebsiteSource(
                displayName: "Website",
                webDomainToken: token
            )
            sources.append(.website(webSource))
        }

        return sources
    }
}
