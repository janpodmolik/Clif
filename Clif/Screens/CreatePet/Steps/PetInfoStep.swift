import SwiftUI

struct PetInfoStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case purpose
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        VStack(spacing: 8) {
            Text("Name your pet")
                .font(.title3.weight(.semibold))

            Text("Give your new companion a name and purpose")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    TextField("e.g. Fern", text: $coordinator.petName)
                        .textFieldStyle(GlassTextFieldStyle())
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .purpose
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Purpose")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("(optional)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    TextField("e.g. Reduce social media", text: $coordinator.petPurpose)
                        .textFieldStyle(GlassTextFieldStyle())
                        .focused($focusedField, equals: .purpose)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)

            Spacer()
        }
        .padding(.top)
        .onAppear {
            focusedField = .name
        }
    }
}

// MARK: - Glass Text Field Style

private struct GlassTextFieldStyle: TextFieldStyle {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 14
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Layout.padding)
            .glassBackground(cornerRadius: Layout.cornerRadius)
    }
}

#if DEBUG
#Preview {
    PetInfoStep()
        .environment(CreatePetCoordinator())
}
#endif
