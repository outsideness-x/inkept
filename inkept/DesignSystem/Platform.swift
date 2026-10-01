import SwiftUI

#if canImport(UIKit)
import UIKit

typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformImage = UIImage
#else
import AppKit

typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformImage = NSImage
#endif

enum RemnPlatform {
    static var isMac: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    /// The space under a button pinned to the foot of a page. On iPhone and iPad the home indicator
    /// already leaves room below it; a Mac window's edge doesn't.
    static var bottomButtonPadding: CGFloat { isMac ? 22 : 8 }
}

extension View {
    /// remn draws its own navigation chrome, so the system bar stays out of the way.
    @ViewBuilder
    func remnHidesSystemBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        navigationBarBackButtonHidden(true)
            .toolbar(removing: .sidebarToggle)
        #endif
    }

    /// On the Mac a sheet only grows as large as its content asks, so give it a comfortable page.
    @ViewBuilder
    func remnSheetFrame(width: CGFloat = 560, height: CGFloat = 640) -> some View {
        #if os(macOS)
        frame(minWidth: width, idealWidth: width, minHeight: height, idealHeight: height)
        #else
        self
        #endif
    }

    /// Covers the whole screen on iPhone and iPad, and the whole window on the Mac.
    @ViewBuilder
    func remnFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, content: content)
        #else
        modifier(WindowCover(isPresented: isPresented, cover: content))
        #endif
    }
}

#if os(macOS)
/// A full-window page laid over everything else, sliding up like a new sheet of paper.
private struct WindowCover<Cover: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    let cover: () -> Cover

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    cover()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background { PaperBackground() }
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: .bottom).combined(with: .opacity)
                        )
                        .zIndex(500)
                }
            }
            .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0.12), value: isPresented)
    }
}
#endif
