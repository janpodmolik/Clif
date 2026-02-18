import SwiftUI

enum AppFont {
    static func quicksand(_ style: Font.TextStyle, weight: Weight = .regular) -> Font {
        .custom(weight.fontName, size: style.defaultSize, relativeTo: style)
    }

    enum Weight {
        case light
        case regular
        case medium
        case semiBold
        case bold

        var fontName: String {
            switch self {
            case .light: "Quicksand-Light"
            case .regular: "Quicksand-Regular"
            case .medium: "Quicksand-Medium"
            case .semiBold: "Quicksand-SemiBold"
            case .bold: "Quicksand-Bold"
            }
        }
    }
}

private extension Font.TextStyle {
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}
