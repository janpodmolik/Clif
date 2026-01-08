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
    private var currentMood: Mood = .happy

    // MARK: - Public Methods

    /// Start automatic random triggers.
    func startAutoTriggers(mood: Mood) {
        currentMood = mood
        stopAutoTriggers()
        scheduleNextAutoTrigger()
    }

    /// Stop automatic triggers.
    func stopAutoTriggers() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    /// Update current mood without restarting timer.
    func updateMood(_ mood: Mood) {
        currentMood = mood
    }

    /// Attempt to trigger bubble on tap interaction.
    /// - Returns: true if bubble was triggered
    @discardableResult
    func triggerOnTap(mood: Mood) -> Bool {
        guard !isOnCooldown, !isVisible else { return false }

        // Random chance
        guard Double.random(in: 0...1) < tapTriggerProbability else {
            return false
        }

        showBubble(mood: mood, source: .mood)
        return true
    }

    /// Force show bubble (for debug purposes).
    func forceShow(mood: Mood, source: EmojiSource = .random, position: SpeechBubblePosition? = nil, customText: String? = nil) {
        showBubble(mood: mood, source: source, forcedPosition: position, customText: customText)
    }

    /// Immediately hide current bubble.
    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        currentConfig = nil
    }

    // MARK: - Private Methods

    private func showBubble(mood: Mood, source: EmojiSource, forcedPosition: SpeechBubblePosition? = nil, customText: String? = nil) {
        // Select emojis
        let emojis = EmojiSet.selectEmojis(source: source, mood: mood)

        // Create config
        let config = SpeechBubbleConfig(
            position: forcedPosition ?? .random(),
            emojis: emojis,
            customText: customText,
            mood: mood,
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
                // 50% mood-based, 50% random for auto triggers
                let source: EmojiSource = Bool.random() ? .mood : .random
                self.showBubble(mood: self.currentMood, source: source)
            }

            self.scheduleNextAutoTrigger()
        }
    }
}
