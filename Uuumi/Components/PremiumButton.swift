import SwiftUI

struct PremiumButton: View {
    let title: String
    let style: Style
    let action: () -> Void

    enum Style {
        case prominent
        case inline
    }

    init(_ title: String = "Get Premium", style: Style = .prominent, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                Text(title)
            }
            .modify { content in
                switch style {
                case .prominent:
                    content
                        .font(.headline)
                        .foregroundStyle(Color(white: 0.1))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PremiumGold"), in: RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: 26)))
                case .inline:
                    content
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("PremiumGold"))
                }
            }
        }
    }
}

private extension View {
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}
