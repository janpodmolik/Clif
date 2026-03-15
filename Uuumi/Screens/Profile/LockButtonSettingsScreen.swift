import SwiftUI

struct LockButtonSettingsScreen: View {
    @AppStorage(DefaultsKeys.lockButtonSide) private var lockButtonSide: LockButtonSide = .trailing
    @AppStorage(DefaultsKeys.lockButtonSize) private var lockButtonSize: LockButtonSize = .normal

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Position")
                        .fontWeight(.bold)
                    Text("Button placement on screen.")
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
                    Text("Size")
                        .fontWeight(.bold)
                    Text("Lock button size.")
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
                    Text("How It Works")
                        .fontWeight(.bold)
                    Text("Locking activates a break — selected apps get blocked. Unlocking ends the break.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Lock Button")
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
