import Foundation

/// A link from one note to another, as written in it.
struct NoteLink: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// `[[Note]]` or `[[Folder/Note#Heading|shown]]`, found by name the way Obsidian finds it.
        case wiki
        /// `[text](Other%20note.md)`, a path from the note's own folder.
        case path
    }

    var kind: Kind
    /// The name or path, without a `#heading`.
    var target: String
}

/// The first thing in a note worth showing as a picture on a card.
enum NoteCover: Hashable, Sendable {
    /// A picture, as linked from the note.
    case image(String)
    /// A formula on a line of its own, in LaTeX.
    case math(String)
    /// A Typst block's source.
    case typst(String)
    /// The first lines of a code block.
    case code(language: String, lines: [String])
}

/// What the board, the graph and the timeline need from a note, read in one pass over its text.
struct NoteOutline: Equatable, Sendable {
    var links: [NoteLink] = []
    var cover: NoteCover?
    /// A few lines of what the note says, without Markdown punctuation.
    var excerpt = ""

    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "heic", "heif", "tif", "tiff", "bmp", "svg"]

    init(_ body: String, excerptLimit: Int = 240) {
        var fence: (marker: String, language: String, lines: [String])?
        var math: [String]?
        var excerpt: [String] = []
        var excerptLength = 0
        var seen = Set<NoteLink>()

        func addLink(_ link: NoteLink) {
            guard !link.target.isEmpty, seen.insert(link).inserted else { return }
            links.append(link)
        }
        func appendExcerpt(_ trimmed: String) {
            guard excerptLength < excerptLimit, let clean = Self.readableLine(trimmed) else { return }
            let room = excerptLimit - excerptLength
            excerpt.append(clean.count > room ? String(clean.prefix(room)) + "…" : clean)
            excerptLength += clean.count
        }

        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if var open = fence {
                if trimmed.hasPrefix(open.marker) {
                    if cover == nil {
                        if open.language == "typst" {
                            cover = .typst(open.lines.joined(separator: "\n"))
                        } else if open.lines.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                            cover = .code(language: open.language, lines: Array(open.lines.prefix(6)))
                        }
                    }
                    fence = nil
                } else {
                    open.lines.append(line)
                    fence = open
                }
                continue
            }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let marker = String(trimmed.prefix(3))
                let language = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    .split(separator: " ").first.map { String($0).lowercased() } ?? ""
                fence = (marker, language, [])
                continue
            }
            if var formula = math {
                if trimmed == "$$" {
                    if cover == nil, !formula.isEmpty { cover = .math(formula.joined(separator: "\n")) }
                    math = nil
                } else {
                    formula.append(trimmed)
                    math = formula
                }
                continue
            }
            if trimmed == "$$" {
                math = []
                continue
            }
            if trimmed.count > 4, trimmed.hasPrefix("$$"), trimmed.hasSuffix("$$") {
                if cover == nil { cover = .math(String(trimmed.dropFirst(2).dropLast(2))) }
                continue
            }

            // Most lines are plain words, with nothing to find in them.
            guard line.contains("[") else {
                appendExcerpt(trimmed)
                continue
            }
            // Code spans aren't links or pictures.
            let text = line.contains("`") ? line.replacingOccurrences(of: #"`[^`]*`"#, with: " ", options: .regularExpression) : line
            let range = NSRange(text.startIndex..., in: text)
            for match in Self.markdownImage.matches(in: text, range: range) {
                if cover == nil, let link = Range(match.range(at: 1), in: text) { cover = .image(String(text[link])) }
            }
            for match in Self.embed.matches(in: text, range: range) {
                guard let name = Range(match.range(at: 1), in: text) else { continue }
                let target = String(text[name]).trimmingCharacters(in: .whitespaces)
                if Self.imageExtensions.contains((target as NSString).pathExtension.lowercased()) {
                    if cover == nil { cover = .image(target) }
                } else {
                    addLink(NoteLink(kind: .wiki, target: Self.withoutHeading(target)))
                }
            }
            for match in Self.wikiLink.matches(in: text, range: range) {
                guard let name = Range(match.range(at: 1), in: text) else { continue }
                addLink(NoteLink(kind: .wiki, target: Self.withoutHeading(String(text[name])).trimmingCharacters(in: .whitespaces)))
            }
            for match in Self.markdownLink.matches(in: text, range: range) {
                guard let href = Range(match.range(at: 1), in: text) else { continue }
                var target = Self.withoutHeading(String(text[href]))
                target = target.removingPercentEncoding ?? target
                let ext = (target as NSString).pathExtension.lowercased()
                guard !target.contains("://"), !target.hasPrefix("mailto:"), VaultPath.noteExtensions.contains(ext) else { continue }
                addLink(NoteLink(kind: .path, target: target))
            }

            appendExcerpt(trimmed)
        }
        self.excerpt = excerpt.joined(separator: "\n")
    }

    private static func withoutHeading(_ target: String) -> String {
        guard let hash = target.firstIndex(of: "#") else { return target }
        return String(target[..<hash])
    }

    /// A line as it reads, or nothing for lines that are only structure.
    private static func readableLine(_ trimmed: String) -> String? {
        guard !trimmed.isEmpty, trimmed != "---", trimmed != "***",
              trimmed.range(of: #"^#{1,6}\s"#, options: .regularExpression) == nil,
              trimmed.range(of: #"^!\[.*\]\(.*\)$|^!\[\[.*\]\]$"#, options: .regularExpression) == nil,
              !trimmed.hasPrefix("|")
        else { return nil }
        let isItem = trimmed.range(of: #"^([-*+]|\d+\.)\s+"#, options: .regularExpression) != nil
        let line = NoteText.plain(
            trimmed
                .replacingOccurrences(of: #"^(>\s*)+"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"^([-*+]|\d+\.)\s+(\[[ xX]\]\s+)?"#, with: "", options: .regularExpression)
        )
        guard !line.isEmpty else { return nil }
        return isItem ? "• " + line : line
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are constants; a typo is a programming error caught by the tests.
        try! NSRegularExpression(pattern: pattern)
    }

    private static let markdownImage = regex(#"!\[[^\]\n]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#)
    private static let embed = regex(#"!\[\[([^\]|\n]+?)(?:\|[^\]\n]*)?\]\]"#)
    private static let wikiLink = regex(#"(?<!!)\[\[([^\]|\n]+)(?:\|[^\]\n]*)?\]\]"#)
    private static let markdownLink = regex(#"(?<![!\]])\[[^\]\n]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#)
}

extension NoteText {
    /// Inline `$formulas$` written out the way they'd read on paper, for previews that can't typeset:
    /// `$\lambda^2 \le \frac{a}{b}$` becomes `λ² ≤ a/b`.
    static func readableMath(in text: String) -> String {
        guard text.contains("$") else { return text }
        let nsText = text as NSString
        var result = ""
        var last = 0
        for match in inlineMath.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            result += nsText.substring(with: NSRange(location: last, length: match.range.location - last))
            result += readable(latex: nsText.substring(with: match.range(at: 1)))
            last = NSMaxRange(match.range)
        }
        return result + nsText.substring(from: last)
    }

    /// The same rule the editor uses: no space just inside the dollars, and no digit straight after, so prices stay prices.
    private static let inlineMath = try! NSRegularExpression(pattern: #"(?<![\\$])\$(?!\s)([^$\n]+?)(?<![\s\\])\$(?![$\d])"#)

    static func readable(latex: String) -> String {
        var text = latex
        if text.contains("\\") {
            for (pattern, template) in Self.structural {
                text = pattern.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
            }
            text = commandsReplaced(in: text)
            // A fraction of two single symbols needs no brackets: (a)/(b) reads as a/b.
            text = text.replacingOccurrences(of: #"\(([^\s()/]{1,2})\)/\(([^\s()/]{1,2})\)"#, with: "$1/$2", options: .regularExpression)
        }
        text = scripted(text, marker: "^", map: Self.superscripts)
        text = scripted(text, marker: "_", map: Self.subscripts)
        text = text
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespaces)
    }

    /// `\lambda` becomes `λ`; commands with nothing to stand for them are left out.
    private static func commandsReplaced(in text: String) -> String {
        var output = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            guard character == "\\" else {
                output.append(character)
                index = text.index(after: index)
                continue
            }
            var end = text.index(after: index)
            while end < text.endIndex, text[end].isASCII, text[end].isLetter {
                end = text.index(after: end)
            }
            let name = String(text[text.index(after: index)..<end])
            if name.isEmpty {
                // An escaped character, like `\{` or `\%`.
                if end < text.endIndex {
                    output.append(text[end])
                    end = text.index(after: end)
                }
            } else {
                output += Self.symbols[name] ?? ""
            }
            index = end
        }
        return output
    }

    /// `x^2`, `x^{-1}` and `a_{12}` in small raised or lowered figures, when every character has one.
    private static func scripted(_ text: String, marker: Character, map: [Character: Character]) -> String {
        var output = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            guard character == marker, text.index(after: index) < text.endIndex else {
                output.append(character)
                index = text.index(after: index)
                continue
            }
            var body = ""
            var end = text.index(after: index)
            if text[end] == "{", let close = text[end...].firstIndex(of: "}") {
                body = String(text[text.index(after: end)..<close])
                end = text.index(after: close)
            } else {
                body = String(text[end])
                end = text.index(after: end)
            }
            let converted = body.compactMap { map[$0] }
            if converted.count == body.count, !body.isEmpty {
                output += String(converted)
            } else {
                output += String(marker) + (body.count > 1 ? "(\(body))" : body)
            }
            index = end
        }
        return output
    }

    private static let structural: [(NSRegularExpression, String)] = [
        (#"\\(?:left|right|big|Big|bigg|Bigg)(?![A-Za-z])"#, ""),
        (#"\\[,;:! ]"#, " "),
        (#"\\q?quad(?![A-Za-z])"#, " "),
        (#"\\(?:text|mathrm|mathbf|mathit|mathsf|operatorname|textbf|textit)\{([^{}]*)\}"#, "$1"),
        (#"\\mathbb\{R\}"#, "ℝ"),
        (#"\\mathbb\{N\}"#, "ℕ"),
        (#"\\mathbb\{Z\}"#, "ℤ"),
        (#"\\mathbb\{Q\}"#, "ℚ"),
        (#"\\mathbb\{C\}"#, "ℂ"),
        (#"\\mathcal\{([^{}]*)\}"#, "$1"),
        (#"\\frac\{([^{}]*)\}\{([^{}]*)\}"#, "($1)/($2)"),
        (#"\\sqrt\{([^{}]*)\}"#, "√($1)"),
        (#"\\(?:vec|overrightarrow)\{([^{}]*)\}"#, "$1⃗"),
        (#"\\bar\{([^{}]*)\}"#, "$1̄"),
        (#"\\hat\{([^{}]*)\}"#, "$1̂"),
        (#"\(([A-Za-z0-9])\)/\(([A-Za-z0-9])\)"#, "$1/$2"),
    ].map { (try! NSRegularExpression(pattern: $0.0), $0.1) }

    private static let symbols: [String: String] = [
        "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ", "epsilon": "ε", "varepsilon": "ε", "zeta": "ζ",
        "eta": "η", "theta": "θ", "vartheta": "ϑ", "iota": "ι", "kappa": "κ", "lambda": "λ", "mu": "μ", "nu": "ν",
        "xi": "ξ", "pi": "π", "rho": "ρ", "sigma": "σ", "tau": "τ", "upsilon": "υ", "phi": "φ", "varphi": "φ",
        "chi": "χ", "psi": "ψ", "omega": "ω", "Gamma": "Γ", "Delta": "Δ", "Theta": "Θ", "Lambda": "Λ", "Xi": "Ξ",
        "Pi": "Π", "Sigma": "Σ", "Phi": "Φ", "Psi": "Ψ", "Omega": "Ω",
        "cdot": "·", "times": "×", "div": "÷", "pm": "±", "mp": "∓", "le": "≤", "leq": "≤", "ge": "≥", "geq": "≥",
        "ne": "≠", "neq": "≠", "approx": "≈", "equiv": "≡", "sim": "∼", "propto": "∝", "to": "→", "rightarrow": "→",
        "leftarrow": "←", "Rightarrow": "⇒", "Leftarrow": "⇐", "Leftrightarrow": "⇔", "iff": "⟺", "implies": "⟹",
        "mapsto": "↦", "infty": "∞", "partial": "∂", "nabla": "∇", "sum": "∑", "prod": "∏", "int": "∫", "iint": "∬",
        "oint": "∮", "sqrt": "√", "in": "∈", "notin": "∉", "ni": "∋", "subset": "⊂", "subseteq": "⊆", "supset": "⊃",
        "supseteq": "⊇", "cup": "∪", "cap": "∩", "setminus": "∖", "forall": "∀", "exists": "∃", "emptyset": "∅",
        "varnothing": "∅", "neg": "¬", "land": "∧", "lor": "∨", "wedge": "∧", "vee": "∨", "oplus": "⊕", "otimes": "⊗",
        "perp": "⊥", "parallel": "∥", "angle": "∠", "circ": "∘", "degree": "°", "dots": "…", "ldots": "…", "cdots": "⋯",
        "top": "ᵀ", "dagger": "†", "hbar": "ħ", "ell": "ℓ", "Re": "ℜ", "Im": "ℑ", "langle": "⟨", "rangle": "⟩",
        "lfloor": "⌊", "rfloor": "⌋", "lceil": "⌈", "rceil": "⌉", "cdotp": "·",
        "det": "det", "ker": "ker", "dim": "dim", "rank": "rank", "sin": "sin", "cos": "cos", "tan": "tan",
        "log": "log", "ln": "ln", "exp": "exp", "lim": "lim", "max": "max", "min": "min", "arg": "arg", "gcd": "gcd",
    ]

    private static let superscripts: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
        "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾", "n": "ⁿ", "i": "ⁱ", "T": "ᵀ", "k": "ᵏ", "x": "ˣ",
        "ᵀ": "ᵀ", "∗": "*", "*": "*", "′": "′", "'": "′",
    ]

    private static let subscripts: [Character: Character] = [
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
        "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎", "i": "ᵢ", "j": "ⱼ", "k": "ₖ", "n": "ₙ", "m": "ₘ",
        "a": "ₐ", "e": "ₑ", "o": "ₒ", "x": "ₓ", "t": "ₜ", "p": "ₚ", "s": "ₛ", "r": "ᵣ", "u": "ᵤ", "v": "ᵥ",
    ]
}
