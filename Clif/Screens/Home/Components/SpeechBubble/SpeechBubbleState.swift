import SwiftUI

/// Observable state manager for speech bubble system.
@Observable
final class SpeechBubbleState {

    // MARK: - Published State

    /// Currently visible speech bubble config (nil = hidden)
    private(set) var currentConfig: SpeechBubbleConfig?

    /// Whether bubble is currently visible
    var isVisible: Bool { currentConfig != nil }

    // MARK: - Configuration

    /// Probability of showing bubble on tap (0.0 - 1.0)
    var tapTriggerProbability: Double = 0.3

    /// Minimum interval between automatic bubbles (seconds)
    var autoTriggerMinInterval: TimeInterval = 15.0

    /// Maximum interval between automatic bubbles (seconds)
    var autoTriggerMaxInterval: TimeInterval = 45.0

    /// Cool-down period after any trigger (seconds)
    var cooldownDuration: TimeInterval = 5.0

    /// Display duration for bubble (seconds)
    var displayDuration: TimeInterval = 3.0

    // MARK: - Internal State

    private var autoTimer: Timer?
    private var hideTimer: Timer?
    private var isOnCooldown: Bool = false
    private var currentWindLevel: WindLevel = .none

    // MARK: - Public Methods

    /// Start automatic random triggers.
    func startAutoTriggers(windLevel: WindLevel) {
        currentWindLevel = windLevel
        stopAutoTriggers()
        scheduleNextAutoTrigger()
    }

    /// Stop automatic triggers.
    func stopAutoTriggers() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    /// Update current wind level without restarting timer.
    func updateWindLevel(_ windLevel: WindLevel) {
        currentWindLevel = windLevel
    }

    /// Attempt to trigger bubble on tap interaction.
    /// - Returns: true if bubble was triggered
    @discardableResult
    func triggerOnTap(windLevel: WindLevel) -> Bool {
        guard !isOnCooldown, !isVisible else { return false }

        // Random chance
        guard Double.random(in: 0...1) < tapTriggerProbability else {
            return false
        }

        showBubble(windLevel: windLevel)
        return true
    }

    /// Force show bubble (for debug purposes).
    func forceShow(windLevel: WindLevel, position: SpeechBubblePosition? = nil, customText: String? = nil) {
        showBubble(windLevel: windLevel, forcedPosition: position, customText: customText)
    }

    /// Immediately hide current bubble.
    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        currentConfig = nil
    }

    // MARK: - Private Methods

    private func showBubble(windLevel: WindLevel, forcedPosition: SpeechBubblePosition? = nil, customText: String? = nil) {
        // Select emojis based on wind level
        let emojis = EmojiSet.selectEmojis(for: windLevel)

        // Create config
        let config = SpeechBubbleConfig(
            position: forcedPosition ?? .random(),
            emojis: emojis,
            customText: customText,
            windLevel: windLevel,
            displayDuration: displayDuration
        )

        // Show
        currentConfig = config
        startCooldown()

        // Schedule hide
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: config.displayDuration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    private func startCooldown() {
        isOnCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) { [weak self] in
            self?.isOnCooldown = false
        }
    }

    private func scheduleNextAutoTrigger() {
        let interval = TimeInterval.random(in: autoTriggerMinInterval...autoTriggerMaxInterval)

        autoTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            if !self.isOnCooldown && !self.isVisible {
                self.showBubble(windLevel: self.currentWindLevel)
            }

            self.scheduleNextAutoTrigger()
        }
    }
}
