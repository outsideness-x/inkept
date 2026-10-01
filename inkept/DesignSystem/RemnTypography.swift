import SwiftUI

/// One hand, several sizes. Every style scales with Dynamic Type.
enum RemnTypography {
    static func display(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom("Neucha", size: size, relativeTo: textStyle)
    }

    static var wordmark: Font { display(44, relativeTo: .largeTitle) }
    static var pageTitle: Font { display(36, relativeTo: .largeTitle) }
    static var sectionTitle: Font { display(25, relativeTo: .title3) }
    static var navigationTitle: Font { display(23, relativeTo: .headline) }
    static var rowTitle: Font { display(26, relativeTo: .title3) }
    static var control: Font { display(21, relativeTo: .body) }
    static var body: Font { display(20, relativeTo: .body) }
    static var note: Font { display(18, relativeTo: .subheadline) }
    static var caption: Font { display(16, relativeTo: .footnote) }
    static var cardText: Font { display(23, relativeTo: .body) }
    static var studyText: Font { display(27, relativeTo: .title3) }

    static var isDisplayFontAvailable: Bool {
        PlatformFont(name: "Neucha", size: 17) != nil
    }
}
