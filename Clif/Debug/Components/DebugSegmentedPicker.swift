#if DEBUG
import SwiftUI

/// Custom segmented picker that works reliably inside ScrollView.
/// Native Picker with .segmented style has gesture recognition issues in ScrollView.
struct DebugSegmentedPicker<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    init(
        _ options: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String
    ) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .font(.footnote.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selection == option
                                ? Color.accentColor
                                : Color.clear
                        )
                        .foregroundStyle(
                            selection == option
                                ? .white
                                : .primary
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Convenience initializers

extension DebugSegmentedPicker where T: CaseIterable, T: RawRepresentable, T.RawValue == String {
    init(selection: Binding<T>) {
        self.init(
            Array(T.allCases) as! [T],
            selection: selection,
            label: { $0.rawValue }
        )
    }
}

extension DebugSegmentedPicker {
    init(_ options: [T], selection: Binding<T>) where T: CustomStringConvertible {
        self.init(options, selection: selection, label: { $0.description })
    }
}

#Preview {
    VStack(spacing: 20) {
        DebugSegmentedPicker(
            ["One", "Two", "Three"],
            selection: .constant("Two"),
            label: { $0 }
        )

        DebugSegmentedPicker(
            [1, 2, 3, 4],
            selection: .constant(2),
            label: { "\($0)" }
        )
    }
    .padding()
}
#endif
