import SwiftUI

struct LockButtonSettingsScreen: View {
    @AppStorage(DefaultsKeys.lockButtonSide) private var lockButtonSide: LockButtonSide = .trailing
    @AppStorage(DefaultsKeys.lockButtonSize) private var lockButtonSize: LockButtonSize = .normal

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pozice")
                        .fontWeight(.bold)
                    Text("Umístění tlačítka na obrazovce.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                ChipPicker(
                    options: LockButtonSide.allCases,
                    selection: $lockButtonSide,
                    label: { $0.label }
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Velikost")
                        .fontWeight(.bold)
                    Text("Velikost lock tlačítka.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                ChipPicker(
                    options: LockButtonSize.allCases,
                    selection: $lockButtonSize,
                    label: { $0.label }
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jak to funguje")
                        .fontWeight(.bold)
                    Text("Zamknutím aktivuješ break — vybrané aplikace se zablokují. Odemknutím break ukončíš.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Lock tlačítko")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LockButtonSettingsScreen()
    }
}
#endif
