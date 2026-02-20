import SwiftUI

struct TypewriterText: View {
    let text: String
    var characterDelay: TimeInterval = 0.06
    var haptic: Bool = true
    var active: Bool = true
    var onCompleted: (() -> Void)?

    @State private var visibleCount = 0
    @State private var hasCompleted = false
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        Text(text)
            .hidden()
            .overlay {
                Text(text.prefix(visibleCount))
            }
            .onChange(of: active) {
                if active { startTypingIfNeeded() }
            }
            .onAppear {
                if active { startTypingIfNeeded() }
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
}

#if DEBUG
#Preview {
    TypewriterText(text: "Hello, this is a typewriter effect...")
        .font(.title3)
        .padding()
}
#endif
