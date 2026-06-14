import Foundation

/// Decides whether the post-evolution App Store review prompt should fire.
///
/// This is a second prompt opportunity, in addition to the one at the end of
/// onboarding. It's reserved for a genuine moment of delight — the first pet
/// evolution — and is only ever requested once per install. Apple additionally
/// rate-limits `requestReview` to three prompts per 365 days and may suppress it
/// entirely, so the actual presentation is never guaranteed; we only guard
/// against asking at the wrong time or more than once.
enum ReviewPromptManager {
    /// Returns `true` exactly once, the first time it's called after an install.
    /// Marks the prompt as consumed so subsequent calls return `false`, ensuring
    /// the single lifetime request is spent on the first evolution and nothing else.
    static func shouldRequestOnFirstEvolution() -> Bool {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: DefaultsKeys.didRequestReview) else { return false }
        defaults.set(true, forKey: DefaultsKeys.didRequestReview)
        return true
    }
}
