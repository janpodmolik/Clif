import SwiftUI

/// Card displayed on empty island prompting user to create their first pet.
struct EmptyIslandCard: View {
    var onCreatePet: () async -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            descriptionSection
            createButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Your island awaits")
                .font(.system(size: 20, weight: .semibold))
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Text("Create a pet to start managing your screen time. Wind intensity reflects how much time you spend in selected apps.")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            HapticType.impactMedium.trigger()
            isLoading = true
            Task {
                await onCreatePet()
                isLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Create Pet")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.blue, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    EmptyIslandCard(onCreatePet: {
        try? await Task.sleep(for: .seconds(2))
    })
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding()
}
#endif
