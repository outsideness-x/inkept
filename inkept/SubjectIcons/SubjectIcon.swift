import SwiftUI

/// A small hand-drawn picture a subject or a folder of notes wears in front of its name.
/// It's stored by `id`, so the catalog can grow without disturbing what's already been chosen.
struct SubjectIcon: Identifiable, Sendable {
    enum Category: String, CaseIterable, Identifiable, Sendable {
        case sciences
        case humanities
        case technology
        case countries
        case things

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .sciences: "icon.category.sciences"
            case .humanities: "icon.category.humanities"
            case .technology: "icon.category.technology"
            case .countries: "icon.category.countries"
            case .things: "icon.category.things"
            }
        }
    }

    let id: String
    let category: Category
    let english: String
    let russian: String
    /// Words that bring this picture to mind, in both languages, for search and suggestions.
    /// A word matches any word that starts with it, so stems like `физик` catch every case ending.
    let keywords: [String]
    /// The colour it's mostly drawn in, for places that echo it, like the graph of notes.
    let tint: InkPencil
    let draw: @Sendable (inout EmojiArt) -> Void

    init(
        _ id: String,
        _ category: Category,
        en english: String,
        ru russian: String,
        tint: InkPencil,
        keys: String = "",
        draw: @escaping @Sendable (inout EmojiArt) -> Void
    ) {
        self.id = id
        self.category = category
        self.english = english
        self.russian = russian
        self.tint = tint
        keywords = keys.split(separator: " ").map { $0.lowercased() }
        self.draw = draw
    }

    /// The name in the language the app is showing.
    var name: String {
        Self.speaksRussian ? russian : english
    }

    func drawing(size: CGFloat) -> EmojiDrawing {
        EmojiRenderer.drawing(key: id, size: size, seed: id.inkSeed) {
            var art = EmojiArt()
            draw(&art)
            return art
        }
    }

    private static let speaksRussian = Bundle.main.preferredLocalizations.first?.hasPrefix("ru") == true
}

extension SubjectIcon: Hashable {
    static func == (lhs: SubjectIcon, rhs: SubjectIcon) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - The catalog

extension SubjectIcon {
    static let all: [SubjectIcon] = sciences + humanities + technology + countries + things

    private static let byID: [String: SubjectIcon] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// The icon stored as `id`; nothing for an id this version of the app doesn't know.
    static func named(_ id: String?) -> SubjectIcon? {
        id.flatMap { byID[$0] }
    }

    static func inCategory(_ category: Category) -> [SubjectIcon] {
        all.filter { $0.category == category }
    }

    /// What a name like "Linear algebra" or "Испанский" calls to mind, best first.
    static func suggestions(for name: String, limit: Int = 6) -> [SubjectIcon] {
        ranked(by: words(in: name), typing: false).prefix(limit).map { $0 }
    }

    /// Icons whose names or keywords start with every word typed, best first.
    static func search(_ query: String) -> [SubjectIcon] {
        let words = words(in: query)
        guard !words.isEmpty else { return all }
        return ranked(by: words, typing: true)
    }

    /// A few to start from before a name suggests anything.
    static let starters: [SubjectIcon] = ["math", "atom", "flask", "code", "book", "globe", "palette", "music"]
        .compactMap { named($0) }

    private static func ranked(by words: [String], typing: Bool) -> [SubjectIcon] {
        guard !words.isEmpty else { return [] }
        return all.enumerated()
            .compactMap { index, icon -> (icon: SubjectIcon, score: Double, index: Int)? in
                let score = icon.score(for: words, typing: typing)
                return score > 0 ? (icon, score, index) : nil
            }
            .sorted { $0.score == $1.score ? $0.index < $1.index : $0.score > $1.score }
            .map(\.icon)
    }

    /// The icon's own names count for most, then the first pair of keywords, which say what it's chiefly for.
    private var vocabulary: [(term: String, weight: Double)] {
        (Self.words(in: english) + Self.words(in: russian)).map { ($0, 1.3) }
            + keywords.enumerated().map { ($1, $0 < 2 ? 1.15 : 1) }
    }

    /// How well `words` fit: a whole word beats a stem, and a stem beats a word still being typed.
    /// While searching, every word has to fit something.
    private func score(for words: [String], typing: Bool) -> Double {
        var total: Double = 0
        for word in words {
            var best: Double = 0
            for (term, weight) in vocabulary {
                let quality: Double
                if word == term {
                    quality = 3
                } else if term.count >= 3, word.hasPrefix(term) {
                    quality = 2
                } else if term.hasPrefix(word), typing ? word.count >= 2 : word.count >= 4 && word.count * 10 >= term.count * 7 {
                    quality = typing ? 2 : 1
                } else {
                    continue
                }
                best = max(best, quality * weight)
            }
            if typing, best == 0 { return 0 }
            total += best
        }
        return total
    }

    private static func words(in text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .split { !$0.isLetter && !$0.isNumber && $0 != "+" && $0 != "#" }
            .map(String.init)
            .filter { $0.count >= 2 || $0 == "c" || $0 == "r" }
    }
}

// MARK: - Drawing it

/// A subject's icon, drawn at `size` points square.
struct SubjectIconView: View {
    let icon: SubjectIcon
    var size: CGFloat = 28

    var body: some View {
        Canvas { context, canvas in
            icon.drawing(size: min(canvas.width, canvas.height)).draw(in: &context)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: icon.name))
    }
}
