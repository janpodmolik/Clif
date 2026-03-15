import FamilyControls
import SwiftUI

// MARK: - My Apps Load Button

/// "Použít moje aplikace" button — loads saved preset into the picker.
/// Self-contained: hidden when no saved preset exists.
struct MyAppsLoadButton: View {
    @Binding var selection: FamilyActivitySelection
    var infoMessage = String(localized: "Loads your saved app and category selection. You can manage your saved selection in Profile.")
    var onLoad: (() -> Void)?

    var body: some View {
        if SharedDefaults.hasMyAppsSelection {
            HStack(spacing: 8) {
                Button {
                    if let saved = SharedDefaults.loadMyAppsSelection() {
                        selection = saved
                        onLoad?()
                    }
                } label: {
                    Label("Use my apps", systemImage: "arrow.down.app")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)

                MyAppsInfoButton(message: infoMessage)
            }
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
                Label("Save as my apps", systemImage: "square.and.arrow.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                MyAppsInfoButton(message: String(localized: "Current selection will be saved as your favorite apps. Next time you can quickly load it when creating a new path."))
            }
        }
        .tint(.accentColor)
    }
}

// MARK: - My Apps Info Button

/// Info button (ⓘ) with alert explaining "Moje aplikace" feature.
/// Pass custom `message` to tailor the explanation for each context.
struct MyAppsInfoButton: View {
    var message: String = String(localized: "Save your app and category selection so you can quickly use it when creating a new path. You can manage your saved selection in Profile.")

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
        .alert("My apps", isPresented: $showInfo) {
            Button("OK") {}
        } message: {
            Text(message)
        }
    }
}
