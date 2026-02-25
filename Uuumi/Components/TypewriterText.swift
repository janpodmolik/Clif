import SwiftUI

struct TypewriterText: View {
    let text: String
    var characterDelay: TimeInterval
    var haptic: Bool
    var active: Bool
    var skipRequested: Bool
    var onCompleted: (() -> Void)?

    @State private var visibleCount = 0
    @State private var hasCompleted = false
    @State private var typingTask: Task<Void, Never>?

    init(
        text: String,
        characterDelay: TimeInterval = 0.06,
        haptic: Bool = true,
        active: Bool = true,
        skipRequested: Bool = false,
        onCompleted: (() -> Void)? = nil
    ) {
        self.text = text
        self.characterDelay = characterDelay
        self.haptic = haptic
        self.active = active
        self.skipRequested = skipRequested
        self.onCompleted = onCompleted
    }

    private var styledText: AttributedString {
        var result = AttributedString(text)
        let visibleEnd = result.index(result.startIndex, offsetByCharacters: visibleCount)
        if visibleEnd < result.endIndex {
            result[visibleEnd..<result.endIndex].foregroundColor = .clear
        }
        return result
    }

    var body: some View {
        Text(styledText)
            .onChange(of: active) {
                if active { startTypingIfNeeded() }
            }
            .onChange(of: skipRequested) {
                if skipRequested { completeImmediately() }
            }
            .onAppear {
                if skipRequested {
                    completeImmediately()
                } else if active {
                    startTypingIfNeeded()
                }
            }
            .onDisappear {
                typingTask?.cancel()
            }
    }

    private func startTypingIfNeeded() {
        guard !hasCompleted else { return }

        typingTask = Task {
            for index in visibleCount..<text.count {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(characterDelay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    visibleCount = index + 1

                    if haptic {
                        let character = text[text.index(text.startIndex, offsetBy: index)]
                        if !character.isWhitespace {
                            HapticType.selection.trigger()
                        }
                    }
                }
            }

            await MainActor.run {
                hasCompleted = true
                onCompleted?()
            }
        }
    }

    private func completeImmediately() {
        guard !hasCompleted else { return }
        typingTask?.cancel()
        visibleCount = text.count
        hasCompleted = true
        onCompleted?()
    }
}

#if DEBUG
#Preview {
    TypewriterText(text: "Hello, this is a typewriter effect...")
        .font(.title3)
        .padding()
}
#endif
