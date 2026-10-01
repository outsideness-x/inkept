import SwiftUI

/// Typefaces a note can be written in. Every one is on both iOS and macOS and sets Cyrillic as well as Latin.
enum NoteFont: String, CaseIterable, Identifiable, Sendable {
    /// The hand the rest of remn is drawn in.
    case neucha
    case sfPro
    case sfRounded
    case newYork
    case iowan
    case charter
    case athelas
    case avenirNext
    case seravek
    case georgia
    case hoefler
    case sfMono

    var id: String { rawValue }

    static let `default` = NoteFont.neucha

    init(frontMatter value: String?) {
        self = value.flatMap { NoteFont(rawValue: $0) } ?? .default
    }

    var displayName: String {
        switch self {
        case .neucha: "Neucha"
        case .sfPro: "SF Pro"
        case .sfRounded: "SF Rounded"
        case .newYork: "New York"
        case .iowan: "Iowan Old Style"
        case .charter: "Charter"
        case .athelas: "Athelas"
        case .avenirNext: "Avenir Next"
        case .seravek: "Seravek"
        case .georgia: "Georgia"
        case .hoefler: "Hoefler Text"
        case .sfMono: "SF Mono"
        }
    }

    /// A few words about the face, shown under its name in the picker.
    var note: LocalizedStringKey {
        switch self {
        case .neucha: "font.note.neucha"
        case .sfPro: "font.note.sfPro"
        case .sfRounded: "font.note.sfRounded"
        case .newYork: "font.note.newYork"
        case .iowan: "font.note.iowan"
        case .charter: "font.note.charter"
        case .athelas: "font.note.athelas"
        case .avenirNext: "font.note.avenirNext"
        case .seravek: "font.note.seravek"
        case .georgia: "font.note.georgia"
        case .hoefler: "font.note.hoefler"
        case .sfMono: "font.note.sfMono"
        }
    }

    /// Faces without a bold or italic cut get them drawn: a second pass of ink, or a slant.
    var hasBoldCut: Bool { self != .neucha }
    var hasItalicCut: Bool { self != .neucha }

    /// How big body text is set: a handwriting face needs more size to read as easily as a text face.
    var bodySize: CGFloat {
        let base: CGFloat
        switch self {
        case .neucha: base = 21
        case .sfMono: base = 15.5
        case .avenirNext, .seravek, .sfPro, .sfRounded: base = 17.5
        default: base = 18.5
        }
        return RemnPlatform.isMac ? (base * 0.88).rounded() : base
    }

    /// Extra space between lines, as a fraction of the size.
    var leading: CGFloat {
        switch self {
        case .neucha: 0.2
        case .sfMono: 0.35
        default: 0.4
        }
    }

    func platformFont(size: CGFloat, bold: Bool = false, italic: Bool = false) -> PlatformFont {
        var font: PlatformFont
        switch self {
        case .neucha:
            font = PlatformFont(name: "Neucha", size: size) ?? .systemFont(ofSize: size)
        case .sfPro:
            font = .systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        case .sfRounded:
            font = Self.system(size: size, weight: bold ? .semibold : .regular, design: .rounded)
        case .newYork:
            font = Self.system(size: size, weight: bold ? .semibold : .regular, design: .serif)
        case .sfMono:
            font = .monospacedSystemFont(ofSize: size, weight: bold ? .semibold : .regular)
        case .iowan:
            font = PlatformFont(name: bold ? "IowanOldStyle-Bold" : "IowanOldStyle-Roman", size: size) ?? .systemFont(ofSize: size)
        case .charter:
            font = PlatformFont(name: bold ? "Charter-Bold" : "Charter-Roman", size: size) ?? .systemFont(ofSize: size)
        case .athelas:
            font = PlatformFont(name: bold ? "Athelas-Bold" : "Athelas-Regular", size: size) ?? .systemFont(ofSize: size)
        case .avenirNext:
            font = PlatformFont(name: bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular", size: size) ?? .systemFont(ofSize: size)
        case .seravek:
            font = PlatformFont(name: bold ? "Seravek-Medium" : "Seravek", size: size) ?? .systemFont(ofSize: size)
        case .georgia:
            font = PlatformFont(name: bold ? "Georgia-Bold" : "Georgia", size: size) ?? .systemFont(ofSize: size)
        case .hoefler:
            font = PlatformFont(name: bold ? "HoeflerText-Black" : "HoeflerText-Regular", size: size) ?? .systemFont(ofSize: size)
        }
        if italic, hasItalicCut {
            font = Self.withItalic(font)
        }
        return font
    }

    /// The SwiftUI face, for the picker and the note's title.
    func font(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        switch self {
        case .neucha: .custom("Neucha", size: size, relativeTo: style)
        case .sfPro: .system(size: size)
        case .sfRounded: .system(size: size, design: .rounded)
        case .newYork: .system(size: size, design: .serif)
        case .sfMono: .system(size: size, design: .monospaced)
        default: Font(platformFont(size: size) as CTFont)
        }
    }

    private static func system(size: CGFloat, weight: PlatformFont.Weight, design: PlatformFontDescriptor.SystemDesign) -> PlatformFont {
        let base = PlatformFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        #if canImport(UIKit)
        return PlatformFont(descriptor: descriptor, size: size)
        #else
        return PlatformFont(descriptor: descriptor, size: size) ?? base
        #endif
    }

    private static func withItalic(_ font: PlatformFont) -> PlatformFont {
        #if canImport(UIKit)
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.traitItalic)) else {
            return font
        }
        return PlatformFont(descriptor: descriptor, size: font.pointSize)
        #else
        let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.italic))
        return PlatformFont(descriptor: descriptor, size: font.pointSize) ?? font
        #endif
    }
}

#if canImport(UIKit)
typealias PlatformFontDescriptor = UIFontDescriptor
#else
typealias PlatformFontDescriptor = NSFontDescriptor
#endif
