import FamilyControls
import SwiftUI

// MARK: - My Apps Load Button

/// "Použít moje aplikace" button — loads saved preset into the picker.
/// Self-contained: hidden when no saved preset exists.
struct MyAppsLoadButton: View {
    @Binding var selection: FamilyActivitySelection
    var onLoad: (() -> Void)?

    var body: some View {
        if SharedDefaults.hasMyAppsSelection {
            Button {
                if let saved = SharedDefaults.loadMyAppsSelection() {
                    selection = saved
                    onLoad?()
                }
            } label: {
                Label("Použít moje aplikace", systemImage: "arrow.down.app")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Save As My Apps Toggle

/// Checkbox toggle — "Uložit jako moje aplikace".
/// Parent owns the boolean state and acts on it when its own save fires.
struct SaveAsMyAppsToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                Label("Uložit jako moje aplikace", systemImage: "square.and.arrow.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                MyAppsInfoButton(message: "Aktuální výběr se uloží jako tvoje oblíbené aplikace. Příště ho můžeš rychle načíst při vytváření nové cesty.")
            }
        }
        .tint(.accentColor)
    }
}

// MARK: - My Apps Info Button

/// Info button (ⓘ) with alert explaining "Moje aplikace" feature.
/// Pass custom `message` to tailor the explanation for each context.
struct MyAppsInfoButton: View {
    var message: String = "Ulož si výběr aplikací a kategorií, abys ho mohl rychle použít při vytváření nové cesty. Uložený výběr můžeš spravovat v Profilu."

    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.subheadline)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .alert("Moje aplikace", isPresented: $showInfo) {
            Button("OK") {}
        } message: {
            Text(message)
        }
    }
}
