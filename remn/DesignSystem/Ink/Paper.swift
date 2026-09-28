import SwiftUI

/// The sheet everything is drawn on: warm paper with a faint tooth.
struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var tone: Color = .remnPaper

    var body: some View {
        Rectangle()
            .fill(tone)
            .colorEffect(ShaderLibrary.remnPaperGrain(.float(colorScheme == .dark ? 0.0086 : 0.0118)))
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
