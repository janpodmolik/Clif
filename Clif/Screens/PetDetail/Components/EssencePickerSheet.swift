import SwiftUI

struct EssencePickerSheet: View {
    var onSelect: (Essence) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEssence: Essence?
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    essenceList
                }
                .padding()
            }
            .navigationTitle("Choose Essence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Apply \(selectedEssence?.displayName ?? "") Essence?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Apply Essence") {
                    if let essence = selectedEssence {
                        onSelect(essence)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectedEssence = nil
                }
            } message: {
                Text("This choice is permanent and cannot be changed.")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.green.gradient)

            Text("Select an essence to determine your pet's evolution path")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var essenceList: some View {
        VStack(spacing: 12) {
            ForEach(Essence.allCases, id: \.self) { essence in
                EssenceRow(essence: essence) {
                    selectedEssence = essence
                    showConfirmation = true
                }
            }
        }
    }
}

// MARK: - Essence Row

private struct EssenceRow: View {
    let essence: Essence
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(essence.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(essence.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(essence.maxPhases) evolution phases")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(essence.themeColor)
            }
            .padding()
            .background(rowBackground(for: essence))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rowBackground(for essence: Essence) -> some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(essence.themeColor.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 16)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(essence.themeColor.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(essence.themeColor.opacity(0.15), lineWidth: 1)
                }
        }
    }
}

#if DEBUG
#Preview {
    EssencePickerSheet { essence in
        print("Selected: \(essence)")
    }
}
#endif
