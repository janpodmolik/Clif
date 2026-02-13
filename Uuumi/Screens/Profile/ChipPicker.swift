import SwiftUI

// MARK: - Single Select

struct ChipPicker<Value: Equatable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = option == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = option
                    }
                } label: {
                    chipLabel(label(option), isSelected: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Multi Select

struct MultiChipPicker: View {
    let options: [(label: String, isOn: Binding<Bool>)]
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        option.isOn.wrappedValue.toggle()
                    }
                } label: {
                    chipLabel(option.label, isSelected: option.isOn.wrappedValue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .opacity(disabled ? 0.4 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Shared Chip Label

private func chipLabel(_ text: String, isSelected: Bool) -> some View {
    HStack(spacing: 6) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .imageScale(.medium)
        Text(text)
    }
    .font(.subheadline.weight(.medium))
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .foregroundStyle(isSelected ? .primary : .tertiary)
    .background(isSelected ? Color(.tertiarySystemFill) : .clear, in: .capsule)
    .overlay(
        Capsule()
            .strokeBorder(isSelected ? .clear : Color(.separator), lineWidth: 0.5)
    )
}
