import Foundation

/// The YAML block at the top of a note, the way Obsidian writes it.
///
/// remn reads and writes only the keys it understands — `tags` and `font` — and keeps every other
/// line exactly where it was, so notes written elsewhere survive a round trip.
struct FrontMatter: Equatable, Sendable {
    private enum Entry: Equatable, Sendable {
        case raw(String)
        case tags
        case font
    }

    private var entries: [Entry] = []
    var tags: [String] = []
    var font: String?

    init() {}

    init(yaml: String) {
        var lines = yaml.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let (key, value) = Self.keyValue(line)
            switch key {
            case "tags", "tag":
                var found = Self.inlineList(value)
                index += 1
                while index < lines.count, let item = Self.blockListItem(lines[index]) {
                    found.append(item)
                    index += 1
                }
                tags = Self.cleaned(found)
                if !entries.contains(.tags) { entries.append(.tags) }
                continue
            case "font":
                font = Self.unquoted(value).nilIfEmpty
                if !entries.contains(.font) { entries.append(.font) }
            default:
                entries.append(.raw(line))
            }
            index += 1
        }
    }

    static func == (lhs: FrontMatter, rhs: FrontMatter) -> Bool {
        lhs.yaml == rhs.yaml
    }

    var isEmpty: Bool {
        tags.isEmpty && font == nil && !entries.contains { if case .raw = $0 { true } else { false } }
    }

    var yaml: String {
        var output: [String] = []
        var wroteTags = false
        var wroteFont = false
        for entry in entries {
            switch entry {
            case .raw(let line):
                output.append(line)
            case .tags:
                if !tags.isEmpty { output.append(tagsLine) }
                wroteTags = true
            case .font:
                if let font { output.append("font: \(font)") }
                wroteFont = true
            }
        }
        if !wroteTags, !tags.isEmpty { output.append(tagsLine) }
        if !wroteFont, let font { output.append("font: \(font)") }
        return output.joined(separator: "\n")
    }

    private var tagsLine: String {
        "tags: [" + tags.map(Self.quotedIfNeeded).joined(separator: ", ") + "]"
    }

    // MARK: - Parsing helpers

    private static func keyValue(_ line: String) -> (String?, String) {
        guard !line.hasPrefix(" "), !line.hasPrefix("\t"), let colon = line.firstIndex(of: ":") else {
            return (nil, "")
        }
        let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
        let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        return (key, value)
    }

    private static func inlineList(_ value: String) -> [String] {
        var value = value
        guard !value.isEmpty else { return [] }
        if value.hasPrefix("["), value.hasSuffix("]") {
            value = String(value.dropFirst().dropLast())
        }
        return value
            .split(separator: ",")
            .map { unquoted($0.trimmingCharacters(in: .whitespaces)) }
    }

    private static func blockListItem(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- ") || trimmed == "-" else { return nil }
        return unquoted(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
    }

    private static func unquoted(_ value: String) -> String {
        guard value.count >= 2,
              let first = value.first, let last = value.last,
              first == last, first == "\"" || first == "'"
        else { return value }
        return String(value.dropFirst().dropLast())
    }

    private static func quotedIfNeeded(_ tag: String) -> String {
        tag.contains(where: { ",[]{}:#\"'".contains($0) }) ? "\"\(tag)\"" : tag
    }

    /// Tags as Obsidian stores them: no leading `#`, no spaces, no duplicates.
    static func cleaned(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags.compactMap { raw in
            let tag = raw
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                .replacingOccurrences(of: " ", with: "-")
            guard !tag.isEmpty, seen.insert(tag.lowercased()).inserted else { return nil }
            return tag
        }
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
