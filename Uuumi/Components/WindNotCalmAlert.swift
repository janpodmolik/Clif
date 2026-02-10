import SwiftUI
import Combine

// MARK: - Sheet

struct WindNotCalmSheet: View {
    @State private var refreshTick = 0
    @Environment(\.dismiss) private var dismiss

    private var isSafe: Bool {
        let _ = refreshTick
        return WindLevel.from(windPoints: SharedDefaults.effectiveWind) == .none
    }

    var body: some View {
        ConfirmationSheet(
            navigationTitle: isSafe ? "Vítr je klidný" : "Vítr musí být klidný",
            height: 320
        ) {
            ConfirmationHeader(
                icon: isSafe ? "sun.max.fill" : "wind",
                iconColor: isSafe ? .green : .orange,
                title: isSafe
                    ? "Vítr klesl na 0 %"
                    : "Sniž vítr na 0 %",
                subtitle: isSafe
                    ? "Můžeš pokračovat v evoluci nebo archivaci."
                    : "Před použitím essence nebo archivací musí být vítr klidný."
            )
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.4), value: isSafe)

            if isSafe {
                ConfirmationAction(
                    icon: "checkmark.circle.fill",
                    title: "Pokračovat",
                    subtitle: "Vítr je klidný",
                    foregroundColor: .green,
                    background: .tinted(.green)
                ) {
                    dismiss()
                }
                .transition(.blurReplace)
            } else {
                ConfirmationAction(
                    icon: "lock.open.fill",
                    title: "Spustit pauzu",
                    subtitle: "Sníží vítr během pauzy"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: .showBreakTypePicker, object: nil)
                    }
                }
                .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isSafe)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            refreshTick += 1
        }
    }
}

// MARK: - Modifier

private struct WindNotCalmSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                WindNotCalmSheet()
            }
    }
}

extension View {
    func windNotCalmSheet(isPresented: Binding<Bool>) -> some View {
        modifier(WindNotCalmSheetModifier(isPresented: isPresented))
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Wind Active") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            WindNotCalmSheet()
        }
}
#endif
