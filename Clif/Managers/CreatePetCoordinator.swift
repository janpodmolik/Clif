import FamilyControls
import SwiftUI

// MARK: - Step Definition

enum CreatePetStep: Int, CaseIterable {
    case appSelection = 0
    case modeSelection = 1
    case modeConfig = 2
    case petInfo = 3
    case petDrop = 4

    var title: String {
        switch self {
        case .appSelection: "Select Apps"
        case .modeSelection: "Choose Mode"
        case .modeConfig: "Configure"
        case .petInfo: "Name Your Pet"
        case .petDrop: "Drop Your Pet"
        }
    }

    var canGoBack: Bool {
        self != .appSelection
    }
}

// MARK: - Drag State

struct BlobDragState: Equatable {
    var isDragging = false
    var dragLocation: CGPoint = .zero
}

// MARK: - Coordinator

@Observable
final class CreatePetCoordinator {
    // MARK: - Sheet State

    var isShowing = false

    // MARK: - Step Navigation

    var currentStep: CreatePetStep = .appSelection

    // MARK: - Collected Data

    var selectedApps = FamilyActivitySelection()
    var selectedMode: PetMode = .daily
    var dailyLimitMinutes: Int = 60
    var dynamicConfig: DynamicModeConfig = .balanced
    var petName: String = ""
    var petPurpose: String = ""

    // MARK: - Drag State (Step 5)

    var dragState = BlobDragState()
    var petDropFrame: CGRect?

    // MARK: - Callbacks

    private var onComplete: ((ActivePet) -> Void)?
    private var cleanupWorkItem: DispatchWorkItem?

    // MARK: - Computed

    var canProceed: Bool {
        switch currentStep {
        case .appSelection:
            !selectedApps.applicationTokens.isEmpty ||
            !selectedApps.categoryTokens.isEmpty ||
            !selectedApps.webDomainTokens.isEmpty
        case .modeSelection:
            true
        case .modeConfig:
            dailyLimitMinutes > 0
        case .petInfo:
            !petName.trimmingCharacters(in: .whitespaces).isEmpty
        case .petDrop:
            true
        }
    }

    var totalSteps: Int {
        CreatePetStep.allCases.count
    }

    // MARK: - Public API

    func show(onComplete: @escaping (ActivePet) -> Void) {
        cleanupWorkItem?.cancel()
        cleanupWorkItem = nil

        self.onComplete = onComplete
        resetWizardState()
        isShowing = true
    }

    func dismiss() {
        isShowing = false

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

    func handleBlobDrop(petManager: PetManager) {
        let limitedSources = createLimitedSources(from: selectedApps)

        let pet: ActivePet
        switch selectedMode {
        case .daily:
            let dailyPet = petManager.createDaily(
                name: petName,
                purpose: petPurpose.isEmpty ? nil : petPurpose,
                dailyLimitMinutes: dailyLimitMinutes,
                limitedSources: limitedSources
            )
            pet = .daily(dailyPet)

        case .dynamic:
            let dynamicPet = petManager.createDynamic(
                name: petName,
                purpose: petPurpose.isEmpty ? nil : petPurpose,
                config: dynamicConfig,
                limitedSources: limitedSources
            )
            pet = .dynamic(dynamicPet)
        }

        // Start monitoring
        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            mode: selectedMode,
            limitMinutes: selectedMode == .daily ? dailyLimitMinutes : Int(dynamicConfig.minutesToBlowAway),
            windPoints: 0,
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
        selectedMode = .daily
        dailyLimitMinutes = 60
        dynamicConfig = .balanced
        petName = ""
        petPurpose = ""
        dragState = BlobDragState()
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
