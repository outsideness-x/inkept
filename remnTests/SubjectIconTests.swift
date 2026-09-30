import SwiftUI
import Testing
@testable import remn

struct SubjectIconTests {
    @Test func everyIconHasItsOwnStableID() {
        let ids = SubjectIcon.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { $0 == $0.lowercased() && !$0.contains(" ") })
        for category in SubjectIcon.Category.allCases {
            #expect(!SubjectIcon.inCategory(category).isEmpty)
        }
    }

    @Test func iconsAreFoundByID() {
        #expect(SubjectIcon.named("atom")?.category == .sciences)
        #expect(SubjectIcon.named("flag-jp")?.category == .countries)
        #expect(SubjectIcon.named("an-icon-from-a-newer-version") == nil)
        #expect(SubjectIcon.named(nil) == nil)
    }

    @Test func namesSuggestIconsThatFit() {
        #expect(SubjectIcon.suggestions(for: "Физика").first?.id == "atom")
        #expect(SubjectIcon.suggestions(for: "Linear Algebra").first?.id == "matrix")
        #expect(SubjectIcon.suggestions(for: "Математический анализ").first?.id == "plot")
        #expect(SubjectIcon.suggestions(for: "Испанский").first?.id == "flag-es")
        #expect(SubjectIcon.suggestions(for: "French").first?.id == "flag-fr")
        #expect(SubjectIcon.suggestions(for: "Английский").prefix(2).map(\.id) == ["flag-us", "flag-gb"])
        #expect(SubjectIcon.suggestions(for: "Python").first?.id == "python")
        #expect(SubjectIcon.suggestions(for: "История России").first?.id == "scroll")
        #expect(SubjectIcon.suggestions(for: "").isEmpty)
        #expect(SubjectIcon.suggestions(for: "Физика", limit: 1).count == 1)
    }

    @Test func searchNeedsEveryWordAndReadsBothLanguages() {
        #expect(SubjectIcon.search("япон").map(\.id) == ["flag-jp", "script-kana"])
        #expect(SubjectIcon.search("chem").contains { $0.id == "flask" })
        #expect(SubjectIcon.search("флаг").allSatisfy { $0.id.hasPrefix("flag-") })
        #expect(SubjectIcon.search("флаг").count == SubjectIcon.inCategory(.countries).filter { $0.id.hasPrefix("flag-") }.count)
        #expect(SubjectIcon.search("star").first?.id == "star")
        #expect(SubjectIcon.search("   ").count == SubjectIcon.all.count)
        #expect(SubjectIcon.search("атом квазар").isEmpty)
    }

    @Test func everyIconDrawsAtEverySize() {
        for icon in SubjectIcon.all {
            for size in [CGFloat(22), 44] {
                let drawing = icon.drawing(size: size)
                #expect(!drawing.pieces.isEmpty, "\(icon.id) drew nothing")
            }
        }
    }

    @Test func drawingsAreRepeatable() {
        let art: EmojiArt = {
            var art = EmojiArt()
            art.shape(.circle(16, 16, 10), .red)
            return art
        }()
        let first = EmojiRenderer.render(art, size: 28, seed: 7)
        let again = EmojiRenderer.render(art, size: 28, seed: 7)
        let other = EmojiRenderer.render(art, size: 28, seed: 8)
        #expect(paths(first) == paths(again))
        #expect(paths(first) != paths(other))
    }

    @Test func svgPathsFlattenIntoOutlines() {
        let outlines = EmojiFigure.path("M2 2 L10 2 C12 2 12 6 10 6 Z M20 20 h4 v4").outlines()
        #expect(outlines.count == 2)
        #expect(outlines[0].closed)
        #expect(!outlines[1].closed)
        #expect(outlines[1].points.last == CGPoint(x: 24, y: 24))
    }

    private func paths(_ drawing: EmojiDrawing) -> [String] {
        drawing.pieces.compactMap { piece in
            if case .fill(let path, _, _, _) = piece { return path.description }
            return nil
        }
    }
}
