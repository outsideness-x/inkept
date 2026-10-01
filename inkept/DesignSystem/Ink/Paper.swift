import SwiftUI

/// The sheet everything is drawn on: a flat, even tone.
struct PaperBackground: View {
    var tone: Color = .inkeptPaper

    var body: some View {
        Rectangle()
            .fill(tone)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

extension View {
    /// Places the view on paper that reaches under the safe areas.
    func paperBackground() -> some View {
        background { PaperBackground() }
    }
}
