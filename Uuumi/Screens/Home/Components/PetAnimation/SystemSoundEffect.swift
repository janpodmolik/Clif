import AudioToolbox

struct SystemSoundEffect: Equatable {
    let id: SystemSoundID

    func play() {
        AudioServicesPlaySystemSound(id)
    }

    /// Light, bell-like tick.
    static let tink = SystemSoundEffect(id: 1103)
    /// Slightly deeper tick.
    static let tock = SystemSoundEffect(id: 1104)

    /// Handy shortlist for quick auditioning.
    static let suggested: [SystemSoundEffect] = [
        .tink,
        .tock
    ]
}

#if DEBUG
import SwiftUI

private struct SystemSoundDebugOption: Identifiable {
    let id = UUID()
    let name: String
    let sound: SystemSoundEffect
}

private struct SystemSoundDebugView: View {
    @State private var customId: String = "1051"
    @State private var showInvalidId = false

    private let options: [SystemSoundDebugOption] = [
        SystemSoundDebugOption(name: "Tink (1103)", sound: .tink),
        SystemSoundDebugOption(name: "Tock (1104)", sound: .tock),
        SystemSoundDebugOption(name: "Bloom (1051)", sound: SystemSoundEffect(id: 1051)),
        SystemSoundDebugOption(name: "Calypso (1052)", sound: SystemSoundEffect(id: 1052)),
        SystemSoundDebugOption(name: "Fanfare (1055)", sound: SystemSoundEffect(id: 1055)),
        SystemSoundDebugOption(name: "Minuet (1057)", sound: SystemSoundEffect(id: 1057)),
        SystemSoundDebugOption(name: "Telegraph (1070)", sound: SystemSoundEffect(id: 1070)),
        SystemSoundDebugOption(name: "Typewriters (1072)", sound: SystemSoundEffect(id: 1072))
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Suggested") {
                    ForEach(options) { option in
                        Button(option.name) {
                            option.sound.play()
                        }
                    }
                }

                Section("Custom ID") {
                    TextField("SystemSoundID", text: $customId)
                        .keyboardType(.numberPad)

                    Button("Play ID") {
                        guard let idValue = UInt32(customId) else {
                            showInvalidId = true
                            return
                        }
                        SystemSoundEffect(id: idValue).play()
                    }
                    .alert("Invalid SystemSoundID", isPresented: $showInvalidId) {
                        Button("OK", role: .cancel) {}
                    }
                }
            }
            .navigationTitle("System Sounds")
        }
    }
}

#Preview {
    SystemSoundDebugView()
}
#endif
