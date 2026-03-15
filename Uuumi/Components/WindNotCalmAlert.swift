import SwiftUI
import Combine

// MARK: - Sheet

struct WindNotCalmSheet: View {
    @Binding var isPresented: Bool
    var onStartBreak: (() -> Void)?

    @State private var refreshTick = 0

    private var isSafe: Bool {
        let _ = refreshTick
        return WindLevel.from(windPoints: SharedDefaults.effectiveWind) == .none
    }

    private var isBreakActive: Bool {
        let _ = refreshTick
        return SharedDefaults.isShieldActive
    }

    var body: some View {
        ConfirmationSheet(
            navigationTitle: isSafe ? "Wind is calm" : "Wind must be calm",
            height: 320
        ) {
            ConfirmationHeader(
                icon: isSafe ? "sun.max.fill" : isBreakActive ? "hourglass" : "wind",
                iconColor: isSafe ? .green : isBreakActive ? .blue : .orange,
                title: isSafe
                    ? "Wind dropped to 0%"
                    : isBreakActive
                        ? "Break is running"
                        : "Lower wind to 0%",
                subtitle: isSafe
                    ? "You can continue with evolution or archiving."
                    : isBreakActive
                        ? "Wait for wind to drop to 0%."
                        : "Wind must be calm before using essence or archiving."
            )
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.4), value: isSafe)
            .animation(.easeInOut(duration: 0.4), value: isBreakActive)

            if isSafe {
                ConfirmationAction(
                    icon: "checkmark.circle.fill",
                    title: "Continue",
                    subtitle: "Wind is calm",
                    foregroundColor: .green,
                    background: .tinted(.green)
                ) {
                    isPresented = false
                }
                .transition(.blurReplace)
            } else if isBreakActive {
                ConfirmationAction(
                    icon: "xmark.circle.fill",
                    title: "Close",
                    subtitle: "Break is still lowering wind"
                ) {
                    isPresented = false
                }
                .transition(.blurReplace)
            } else {
                ConfirmationAction(
                    icon: "lock.open.fill",
                    title: "Start break",
                    subtitle: "Will lower wind during break"
                ) {
                    isPresented = false
                    if let onStartBreak {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onStartBreak()
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: .showBreakTypePicker, object: nil)
                        }
                    }
                }
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isSafe)
        .animation(.easeInOut(duration: 0.4), value: isBreakActive)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            refreshTick += 1
        }
    }
}

// MARK: - Modifier

private struct WindNotCalmSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onStartBreak: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                WindNotCalmSheet(isPresented: $isPresented, onStartBreak: onStartBreak)
            }
    }
}

extension View {
    func windNotCalmSheet(isPresented: Binding<Bool>, onStartBreak: (() -> Void)? = nil) -> some View {
        modifier(WindNotCalmSheetModifier(isPresented: isPresented, onStartBreak: onStartBreak))
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Wind Active") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            WindNotCalmSheet(isPresented: .constant(true))
        }
}
#endif
