import SwiftUI

/// The coloured pencils small pictures are drawn with: muted and a little warm, so they sit on the
/// paper with the ink and the red pencil, and a touch lighter on dark paper.
enum InkPencil: Int, CaseIterable, Sendable {
    case ink
    case graphite
    /// The paper a card is cut from, for pages, highlights and the white of things.
    case paper
    case red
    case rose
    case orange
    case yellow
    case gold
    case lime
    case mint
    case green
    case teal
    case sky
    case blue
    case navy
    case purple
    case brown
    case tan
    case steel
    case terracotta
    /// The white of a flag, which stays light on dark paper, like a sticker.
    case white
    /// The black of a flag, which stays darker than dark paper.
    case black

    var color: Color { Self.colors[rawValue] }

    private static let colors: [Color] = allCases.map { pencil in
        switch pencil {
        case .ink: .remnInk
        case .graphite: .remnGraphite
        case .paper: .remnCardPaper
        case .red: tone(0xC7432F, 0xE2644C)
        case .rose: tone(0xE59AA2, 0xEBADB4)
        case .orange: tone(0xE07D3A, 0xEC9656)
        case .yellow: tone(0xEBBB3F, 0xF0C85A)
        case .gold: tone(0xC9962E, 0xDDB14E)
        case .lime: tone(0x84B652, 0x9CCB6C)
        case .mint: tone(0x4DBF7F, 0x6BD49A)
        case .green: tone(0x4C8A4B, 0x6DAE69)
        case .teal: tone(0x3A8E89, 0x5DB5AE)
        case .sky: tone(0x6FA9D8, 0x8FBEE6)
        case .blue: tone(0x3563A6, 0x6B93D2)
        case .navy: tone(0x283F6E, 0x546FA8)
        case .purple: tone(0x7556A5, 0x9D83CD)
        case .brown: tone(0x8A5C3B, 0xB1835F)
        case .tan: tone(0xDDBE8E, 0xC9AA7C)
        case .steel: tone(0xA6A49E, 0x8E8A83)
        case .terracotta: tone(0xD97757, 0xE3876A)
        case .white: tone(0xFBF8F1, 0xE7E1D4)
        case .black: tone(0x27241F, 0x3A3631)
        }
    }

    private static func tone(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(PlatformColor.remnDynamic(light: light, dark: dark))
    }
}
