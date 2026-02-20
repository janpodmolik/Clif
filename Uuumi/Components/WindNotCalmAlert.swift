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
            navigationTitle: isSafe ? "Vítr je klidný" : "Vítr musí být klidný",
            height: 320
        ) {
            ConfirmationHeader(
                icon: isSafe ? "sun.max.fill" : isBreakActive ? "hourglass" : "wind",
                iconColor: isSafe ? .green : isBreakActive ? .blue : .orange,
                title: isSafe
                    ? "Vítr klesl na 0 %"
                    : isBreakActive
                        ? "Pauza běží"
                        : "Sniž vítr na 0 %",
                subtitle: isSafe
                    ? "Můžeš pokračovat v evoluci nebo archivaci."
                    : isBreakActive
                        ? "Počkej, až vítr klesne na 0 %."
                        : "Před použitím essence nebo archivací musí být vítr klidný."
            )
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.4), value: isSafe)
            .animation(.easeInOut(duration: 0.4), value: isBreakActive)

            if isSafe {
                ConfirmationAction(
                    icon: "checkmark.circle.fill",
                    title: "Pokračovat",
                    subtitle: "Vítr je klidný",
                    foregroundColor: .green,
                    background: .tinted(.green)
                ) {
                    isPresented = false
                }
                .transition(.blurReplace)
            } else if isBreakActive {
                ConfirmationAction(
                    icon: "xmark.circle.fill",
                    title: "Zavřít",
                    subtitle: "Pauza stále snižuje vítr"
                ) {
                    isPresented = false
                }
                .transition(.blurReplace)
            } else {
                ConfirmationAction(
                    icon: "lock.open.fill",
                    title: "Spustit pauzu",
                    subtitle: "Sníží vítr během pauzy"
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
