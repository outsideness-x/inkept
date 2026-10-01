import Foundation

/// A note's Markdown cut into the pieces the live editor styles, hides and draws.
/// Ranges are UTF-16 (`NSRange`) so they can go straight into TextKit.
struct LiveMarkdown: Equatable {
    struct Block: Equatable {
        enum Kind: Equatable {
            case paragraph
            case blank
            case heading(level: Int)
            case quote
            case listItem(ordered: Bool)
            case task(checked: Bool)
            case rule
            case table
            /// A fenced code block; `typst` blocks are drawn by the Typst engine instead of shown as code.
            case code(language: String)
            case math
            /// A picture on a line of its own.
            case image
        }

        var kind: Kind
        /// Whole lines, including the final newline.
        var range: NSRange
        /// The Markdown punctuation at the start of the line: `## `, `> `, `- `, `- [ ] `.
        var marker: NSRange?
        /// For fenced blocks: the opening and closing fence lines, and what's between them.
        var openFence: NSRange?
        var closeFence: NSRange?
        var content: NSRange?
        /// For task items: the `[ ]` box.
        var checkbox: NSRange?

        var isFenced: Bool {
            switch kind {
            case .code, .math: true
            default: false
            }
        }
    }

    struct Inline: Equatable {
        enum Kind: Equatable {
            case strong
            case emphasis
            case strikethrough
            case highlight
            case code
            case math
            case link(url: String)
            case wikiLink(target: String)
            case image(url: String)
            case tag
        }

        var kind: Kind
        var range: NSRange
        /// Punctuation that disappears when the cursor is elsewhere.
        var markers: [NSRange]
        /// What's left when the markers are hidden.
        var content: NSRange
    }

    var blocks: [Block] = []
    var inlines: [Inline] = []

    init(_ text: String) {
        let string = text as NSString
        parseBlocks(string)
        for block in blocks {
            switch block.kind {
            case .paragraph, .heading, .quote, .listItem, .task, .table:
                let start = block.marker.map { NSMaxRange($0) } ?? block.range.location
                let end = Self.lineEnd(of: block.range, in: string)
                if end > start {
                    parseInlines(string, in: NSRange(location: start, length: end - start))
                }
            case .image:
                parseInlines(string, in: NSRange(location: block.range.location, length: Self.lineEnd(of: block.range, in: string) - block.range.location))
            default:
                break
            }
        }
    }

    /// The end of a block's text, before its trailing newline.
    static func lineEnd(of range: NSRange, in string: NSString) -> Int {
        var end = NSMaxRange(range)
        while end > range.location, [10, 13].contains(string.character(at: end - 1)) {
            end -= 1
        }
        return end
    }

    // MARK: - Blocks

    private struct Line {
        var range: NSRange
        var text: String
        var trimmed: String
    }

    private static func lines(of string: NSString) -> [Line] {
        var lines: [Line] = []
        var location = 0
        let length = string.length
        while location < length {
            let range = string.lineRange(for: NSRange(location: location, length: 0))
            let text = string.substring(with: range).trimmingCharacters(in: .newlines)
            lines.append(Line(range: range, text: text, trimmed: text.trimmingCharacters(in: .whitespaces)))
            location = NSMaxRange(range)
        }
        if length == 0 || [10, 13].contains(string.character(at: length - 1)) {
            lines.append(Line(range: NSRange(location: length, length: 0), text: "", trimmed: ""))
        }
        return lines
    }

    private mutating func parseBlocks(_ string: NSString) {
        let lines = Self.lines(of: string)
        var index = 0
        while index < lines.count {
            let line = lines[index]

            if let fence = Self.fence(line.trimmed) {
                var end = index + 1
                while end < lines.count, !Self.closes(fence.marker, lines[end].trimmed) {
                    end += 1
                }
                let closed = end < lines.count
                let last = closed ? end : lines.count - 1
                let range = NSUnionRange(line.range, lines[last].range)
                let contentStart = NSMaxRange(line.range)
                let contentEnd = closed ? lines[end].range.location : NSMaxRange(lines[last].range)
                blocks.append(Block(
                    kind: .code(language: fence.language),
                    range: range,
                    openFence: line.range,
                    closeFence: closed ? lines[end].range : nil,
                    content: NSRange(location: contentStart, length: max(0, contentEnd - contentStart))
                ))
                index = last + 1
                continue
            }

            if line.trimmed.hasPrefix("$$") {
                let rest = line.trimmed.dropFirst(2)
                if rest.hasSuffix("$$"), rest.count >= 2 {
                    // $$ x $$ on one line.
                    let start = (string.substring(with: line.range) as NSString).range(of: "$$").location + line.range.location
                    let open = NSRange(location: start, length: 2)
                    let closeLocation = (string.substring(with: line.range) as NSString)
                        .range(of: "$$", options: .backwards).location + line.range.location
                    blocks.append(Block(
                        kind: .math,
                        range: line.range,
                        openFence: open,
                        closeFence: NSRange(location: closeLocation, length: 2),
                        content: NSRange(location: NSMaxRange(open), length: closeLocation - NSMaxRange(open))
                    ))
                    index += 1
                    continue
                }
                var end = index + 1
                while end < lines.count, !lines[end].trimmed.hasSuffix("$$") {
                    end += 1
                }
                if end < lines.count {
                    let contentStart = line.range.location + (string.substring(with: line.range) as NSString).range(of: "$$").location + 2
                    let closeText = string.substring(with: lines[end].range) as NSString
                    let closeLocation = lines[end].range.location + closeText.range(of: "$$", options: .backwards).location
                    blocks.append(Block(
                        kind: .math,
                        range: NSUnionRange(line.range, lines[end].range),
                        openFence: line.range,
                        closeFence: lines[end].range,
                        content: NSRange(location: contentStart, length: max(0, closeLocation - contentStart))
                    ))
                    index = end + 1
                    continue
                }
            }

            blocks.append(Self.simpleBlock(line))
            index += 1
        }
    }

    private static func fence(_ trimmed: String) -> (marker: String, language: String)? {
        for marker in ["```", "~~~"] where trimmed.hasPrefix(marker) {
            let run = trimmed.prefix { $0 == marker.first }
            let language = trimmed.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
            return (String(run), language.lowercased())
        }
        return nil
    }

    private static func closes(_ marker: String, _ trimmed: String) -> Bool {
        guard let first = marker.first else { return false }
        let run = trimmed.prefix { $0 == first }
        return run.count >= marker.count && trimmed.dropFirst(run.count).trimmingCharacters(in: .whitespaces).isEmpty
    }

    private static func simpleBlock(_ line: Line) -> Block {
        func marker(_ length: Int) -> NSRange {
            NSRange(location: line.range.location, length: length)
        }
        func match(_ pattern: NSRegularExpression) -> NSTextCheckingResult? {
            let text = line.text as NSString
            return pattern.firstMatch(in: line.text, range: NSRange(location: 0, length: text.length))
        }

        guard let first = line.trimmed.first else {
            return Block(kind: .blank, range: line.range)
        }
        // Most lines are prose: only look closer at lines that start with Markdown punctuation.
        switch first {
        case "#":
            if let found = match(headingLine) {
                return Block(kind: .heading(level: found.range(at: 1).length), range: line.range, marker: marker(found.range.length))
            }
        case ">":
            if let found = match(quoteLine) {
                return Block(kind: .quote, range: line.range, marker: marker(found.range.length))
            }
        case "-", "*", "_", "+", "0"..."9":
            if first != "+", !first.isNumber, match(ruleLine) != nil {
                return Block(kind: .rule, range: line.range, marker: marker((line.text as NSString).length))
            }
            if let found = match(listLine) {
                if found.range(at: 4).location != NSNotFound {
                    let box = (line.text as NSString).substring(with: found.range(at: 4))
                    return Block(
                        kind: .task(checked: box != " "),
                        range: line.range,
                        marker: marker(found.range.length),
                        checkbox: NSRange(location: line.range.location + found.range(at: 3).location, length: 3)
                    )
                }
                let bullet = (line.text as NSString).substring(with: found.range(at: 2))
                return Block(kind: .listItem(ordered: bullet.first?.isNumber == true), range: line.range, marker: marker(found.range.length))
            }
        case "!":
            if match(imageLine) != nil {
                return Block(kind: .image, range: line.range)
            }
        case "|":
            if line.trimmed.hasSuffix("|"), line.trimmed.count > 1 {
                return Block(kind: .table, range: line.range)
            }
        default:
            break
        }
        return Block(kind: .paragraph, range: line.range)
    }

    private static let headingLine = regex(#"^(#{1,6})[ \t]+"#)
    private static let ruleLine = regex(#"^ {0,3}([-*_])( *\1){2,} *$"#)
    private static let quoteLine = regex(#"^ {0,3}(> ?)+"#)
    private static let listLine = regex(#"^(\s*)([-*+]|\d{1,9}[.)])[ \t]+(\[([ xX])\][ \t]+)?"#)
    private static let imageLine = regex(#"^\s*!(?:\[[^\]]*\]\([^)]+\)|\[\[[^\]]+\]\])\s*$"#)

    // MARK: - Inline

    private mutating func parseInlines(_ string: NSString, in range: NSRange) {
        let text = string.substring(with: range)
        let base = range.location
        var taken = IndexSet()
        // Paragraphs arrive in order, so sorting each one's own spans keeps the whole list sorted.
        var found: [Inline] = []
        defer { inlines += found.sorted { $0.range.location < $1.range.location } }

        func claim(_ local: NSRange) -> Bool {
            let span = local.location..<NSMaxRange(local)
            guard !taken.intersects(integersIn: span) else { return false }
            taken.insert(integersIn: span)
            return true
        }
        func absolute(_ local: NSRange) -> NSRange {
            NSRange(location: local.location + base, length: local.length)
        }
        func add(_ kind: Inline.Kind, _ match: NSTextCheckingResult, content group: Int, markers: [NSRange]? = nil) {
            let whole = match.range
            let inner = match.range(at: group)
            let hidden = markers ?? [
                NSRange(location: whole.location, length: inner.location - whole.location),
                NSRange(location: NSMaxRange(inner), length: NSMaxRange(whole) - NSMaxRange(inner)),
            ]
            found.append(Inline(
                kind: kind,
                range: absolute(whole),
                markers: hidden.filter { $0.length > 0 }.map(absolute),
                content: absolute(inner)
            ))
        }

        let nsText = text as NSString
        let all = NSRange(location: 0, length: nsText.length)
        // Most paragraphs are plain words; skip every pattern whose punctuation isn't there.
        var present = Set<unichar>()
        for index in 0..<nsText.length {
            let character = nsText.character(at: index)
            if character < 128, "`$![*_~=#".utf16.contains(character) { present.insert(character) }
        }
        guard !present.isEmpty else { return }
        func has(_ characters: String) -> Bool { characters.utf16.contains { present.contains($0) } }

        // Code and math first: nothing inside them is Markdown.
        if has("`") {
            for match in Self.codeSpan.matches(in: text, range: all) where claim(match.range) {
                add(.code, match, content: 2)
            }
        }
        if has("$") {
            for match in Self.inlineMath.matches(in: text, range: all) where claim(match.range) {
                add(.math, match, content: 1)
            }
        }
        guard has("![*_~=#") else { return }
        for match in Self.image.matches(in: text, range: all) where claim(match.range) {
            let url = nsText.substring(with: match.range(at: 2))
            found.append(Inline(kind: .image(url: url), range: absolute(match.range), markers: [absolute(match.range)], content: absolute(match.range(at: 1))))
        }
        for match in Self.embed.matches(in: text, range: all) where claim(match.range) {
            let name = nsText.substring(with: match.range(at: 1))
            found.append(Inline(kind: .image(url: name), range: absolute(match.range), markers: [absolute(match.range)], content: absolute(match.range(at: 1))))
        }
        for match in Self.wikiLink.matches(in: text, range: all) where claim(match.range) {
            let target = nsText.substring(with: match.range(at: 1))
            let shown = match.range(at: 2).location != NSNotFound ? match.range(at: 2) : match.range(at: 1)
            let markers = [
                NSRange(location: match.range.location, length: shown.location - match.range.location),
                NSRange(location: NSMaxRange(shown), length: NSMaxRange(match.range) - NSMaxRange(shown)),
            ]
            found.append(Inline(
                kind: .wikiLink(target: target),
                range: absolute(match.range),
                markers: markers.filter { $0.length > 0 }.map(absolute),
                content: absolute(shown)
            ))
        }
        for match in Self.link.matches(in: text, range: all) where claim(match.range) {
            let url = nsText.substring(with: match.range(at: 2))
            add(.link(url: url), match, content: 1)
        }
        for (pattern, kind, trigger) in [
            (Self.strong, Inline.Kind.strong, "*_"),
            (Self.strikethrough, .strikethrough, "~"),
            (Self.highlight, .highlight, "="),
            (Self.emphasis, .emphasis, "*_"),
        ] where has(trigger) {
            for match in pattern.matches(in: text, range: all) {
                // Emphasis can sit inside strong text, so only code, math and links block it.
                let span = match.range.location..<NSMaxRange(match.range)
                let blocked = found.contains { inline in
                    switch inline.kind {
                    case .code, .math, .image, .link, .wikiLink:
                        let local = inline.range.location - base
                        return (local..<(local + inline.range.length)).overlaps(span)
                    default:
                        return false
                    }
                }
                guard !blocked else { continue }
                add(kind, match, content: 2)
            }
        }
        for match in (has("#") ? Self.tag.matches(in: text, range: all) : []) where claim(match.range(at: 1)) {
            let tag = match.range(at: 1)
            found.append(Inline(kind: .tag, range: absolute(tag), markers: [], content: absolute(tag)))
        }
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are constants; a typo is a programming error caught by the tests.
        try! NSRegularExpression(pattern: pattern)
    }

    private static let codeSpan = regex(#"(`+)(.+?)\1"#)
    private static let inlineMath = regex(#"(?<![\\$])\$(?!\s)([^$\n]+?)(?<![\s\\])\$(?![$\d])"#)
    private static let image = regex(#"!\[([^\]\n]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#)
    private static let embed = regex(#"!\[\[([^\]|\n]+?)(?:\|[^\]\n]*)?\]\]"#)
    private static let wikiLink = regex(#"\[\[([^\]|\n]+)(?:\|([^\]\n]+))?\]\]"#)
    private static let link = regex(#"\[([^\]\n]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#)
    private static let strong = regex(#"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#)
    private static let emphasis = regex(#"(?<![*_\w])([*_])(?=\S)((?:(?!\1).)+?)(?<=\S)\1(?![*_\w])"#)
    private static let strikethrough = regex(#"(~~)(?=\S)(.+?)(?<=\S)~~"#)
    private static let highlight = regex(#"(==)(?=\S)(.+?)(?<=\S)=="#)
    private static let tag = regex(#"(?:^|(?<=[\s(]))(#[\p{L}\p{N}_/-]*[\p{L}_][\p{L}\p{N}_/-]*)"#)
}

extension LiveMarkdown.Block {
    /// Blocks drawn as pictures when the cursor is elsewhere.
    var rendersAsPicture: Bool {
        switch kind {
        case .math, .image: true
        case .code(let language): language == "typst"
        default: false
        }
    }
}

extension LiveMarkdown.Block {
    /// The same block after `delta` characters were added before it, or taken away.
    func shifted(by delta: Int) -> Self {
        func move(_ range: NSRange?) -> NSRange? {
            range.map { NSRange(location: $0.location + delta, length: $0.length) }
        }
        var block = self
        block.range = NSRange(location: range.location + delta, length: range.length)
        block.marker = move(marker)
        block.openFence = move(openFence)
        block.closeFence = move(closeFence)
        block.content = move(content)
        block.checkbox = move(checkbox)
        return block
    }
}
