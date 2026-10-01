import Foundation

/// A change the note toolbar makes to the Markdown around the cursor.
enum NoteInsertion: Equatable {
    case heading
    case bold
    case italic
    case strikethrough
    case highlight
    case inlineCode
    case inlineMath
    case link
    case bullets
    case numbers
    case tasks
    case quote
    case codeBlock
    case mathBlock
    case typst(String)
    case rule
    case table

    struct Edit: Equatable {
        var range: NSRange
        var replacement: String
        /// What to select afterwards, in the text after the edit.
        var selection: NSRange
    }

    func edit(in text: NSString, selection: NSRange) -> Edit {
        let selection = NSRange(
            location: min(selection.location, text.length),
            length: min(selection.length, text.length - min(selection.location, text.length))
        )
        switch self {
        case .bold: return wrap("**", "**", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .italic: return wrap("*", "*", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .strikethrough: return wrap("~~", "~~", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .highlight: return wrap("==", "==", placeholder: String(localized: "insert.placeholder.text"), text, selection)
        case .inlineCode: return wrap("`", "`", placeholder: "code", text, selection)
        case .inlineMath: return wrap("$", "$", placeholder: "x^2", text, selection)
        case .link: return link(text, selection)
        case .heading: return cycleHeading(text, selection)
        case .bullets: return toggleLinePrefix("- ", text, selection)
        case .numbers: return toggleLinePrefix("1. ", text, selection)
        case .tasks: return toggleLinePrefix("- [ ] ", text, selection)
        case .quote: return toggleLinePrefix("> ", text, selection)
        case .codeBlock: return block(open: "```\n", close: "\n```", placeholder: "code", text, selection)
        case .mathBlock: return block(open: "$$\n", close: "\n$$", placeholder: "\\int_0^1 x^2\\,dx = \\frac{1}{3}", text, selection)
        case .typst(let template): return block(open: "```typst\n", close: "\n```", placeholder: template, text, selection)
        case .rule: return block(open: "---", close: "", placeholder: "", text, NSRange(location: NSMaxRange(selection), length: 0))
        case .table:
            let header = String(localized: "insert.table.column")
            return block(
                open: "| \(header) 1 | \(header) 2 |\n| --- | --- |\n| ",
                close: " |  |",
                placeholder: "…",
                text,
                NSRange(location: NSMaxRange(selection), length: 0)
            )
        }
    }

    // MARK: - Inline

    private func wrap(_ open: String, _ close: String, placeholder: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let openLength = (open as NSString).length
        let closeLength = (close as NSString).length
        // Already wrapped: take the markers off again.
        if selection.location >= openLength, NSMaxRange(selection) + closeLength <= text.length,
           text.substring(with: NSRange(location: selection.location - openLength, length: openLength)) == open,
           text.substring(with: NSRange(location: NSMaxRange(selection), length: closeLength)) == close,
           selection.length > 0 {
            let outer = NSRange(location: selection.location - openLength, length: selection.length + openLength + closeLength)
            let inner = text.substring(with: selection)
            return Edit(range: outer, replacement: inner, selection: NSRange(location: outer.location, length: selection.length))
        }
        let inner = selection.length > 0 ? text.substring(with: selection) : placeholder
        let replacement = open + inner + close
        return Edit(
            range: selection,
            replacement: replacement,
            selection: NSRange(location: selection.location + openLength, length: (inner as NSString).length)
        )
    }

    private func link(_ text: NSString, _ selection: NSRange) -> Edit {
        let label = selection.length > 0 ? text.substring(with: selection) : String(localized: "insert.placeholder.link")
        let replacement = "[\(label)](https://)"
        let urlStart = selection.location + (label as NSString).length + 3
        return Edit(range: selection, replacement: replacement, selection: NSRange(location: urlStart, length: 8))
    }

    // MARK: - Lines

    private func lines(_ text: NSString, _ selection: NSRange) -> NSRange {
        text.lineRange(for: selection)
    }

    private func cycleHeading(_ text: NSString, _ selection: NSRange) -> Edit {
        let lineRange = text.lineRange(for: NSRange(location: selection.location, length: 0))
        let line = text.substring(with: lineRange)
        let hashes = line.prefix { $0 == "#" }.count
        let body = hashes > 0 ? String(line.dropFirst(hashes)).drop(while: { $0 == " " }) : Substring(line)
        let next = hashes >= 3 ? 0 : hashes + 1
        let prefix = next == 0 ? "" : String(repeating: "#", count: next) + " "
        let replacement = prefix + body
        let delta = (prefix as NSString).length - (line as NSString).length + (String(body) as NSString).length
        let cursor = max(lineRange.location, min(selection.location + delta, lineRange.location + (replacement as NSString).length))
        return Edit(range: lineRange, replacement: replacement, selection: NSRange(location: cursor, length: 0))
    }

    private func toggleLinePrefix(_ prefix: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let range = lines(text, selection)
        let block = text.substring(with: range)
        var parts = block.components(separatedBy: "\n")
        let trailingNewline = block.hasSuffix("\n")
        if trailingNewline { parts.removeLast() }
        let pattern: String
        switch prefix {
        case "1. ": pattern = #"^\d+\. "#
        case "- [ ] ": pattern = #"^- \[[ xX]\] "#
        default: pattern = "^" + NSRegularExpression.escapedPattern(for: prefix)
        }
        let nonEmpty = parts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let allHave = !nonEmpty.isEmpty && nonEmpty.allSatisfy { $0.range(of: pattern, options: .regularExpression) != nil }
        var number = 0
        let changed = parts.map { line -> String in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty || parts.count == 1 else { return line }
            if allHave {
                return line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            // Swap another list marker for this one rather than stacking them.
            let bare = line.replacingOccurrences(of: #"^(- \[[ xX]\] |[-*+] |\d+\. |> )"#, with: "", options: .regularExpression)
            number += 1
            return (prefix == "1. " ? "\(number). " : prefix) + bare
        }
        let replacement = changed.joined(separator: "\n") + (trailingNewline ? "\n" : "")
        let length = (replacement as NSString).length - (trailingNewline ? 1 : 0)
        let selectionAfter = parts.count == 1
            ? NSRange(location: range.location + length, length: 0)
            : NSRange(location: range.location, length: length)
        return Edit(range: range, replacement: replacement, selection: selectionAfter)
    }

    // MARK: - Blocks

    private func block(open: String, close: String, placeholder: String, _ text: NSString, _ selection: NSRange) -> Edit {
        let inner = selection.length > 0 ? text.substring(with: selection) : placeholder
        var lead = ""
        if selection.location > 0, text.character(at: selection.location - 1) != 10 {
            lead = "\n\n"
        } else if selection.location > 1, text.character(at: selection.location - 2) != 10 {
            lead = "\n"
        }
        var tail = ""
        let end = NSMaxRange(selection)
        if end < text.length {
            tail = text.character(at: end) == 10 ? "\n" : "\n\n"
        } else {
            tail = "\n"
        }
        let replacement = lead + open + inner + close + tail
        let innerStart = selection.location + (lead as NSString).length + (open as NSString).length
        return Edit(
            range: selection,
            replacement: replacement,
            selection: NSRange(location: innerStart, length: (inner as NSString).length)
        )
    }
}

/// Return at the end of a list item starts the next one; Return on an empty item ends the list.
enum ListContinuation {
    static func edit(in text: NSString, at location: Int) -> NoteInsertion.Edit? {
        guard location <= text.length else { return nil }
        let line = text.lineRange(for: NSRange(location: location, length: 0))
        let lineEnd = LiveMarkdown.lineEnd(of: line, in: text)
        let head = text.substring(with: NSRange(location: line.location, length: location - line.location))
        guard let match = head.firstMatch(of: #/^(\s*)(?:([-*+])|(\d{1,9})([.)]))[ \t]+(\[[ xX]\][ \t]+)?|^(\s*)((?:> ?)+)/#) else {
            return nil
        }
        // Nothing to continue inside code or formulas.
        let blocks = LiveMarkdown(text as String).blocks
        let inFence = blocks.contains { block in
            guard block.isFenced else { return false }
            // An unclosed fence runs to the very end, cursor included.
            return NSLocationInRange(location, block.range) || (block.closeFence == nil && location == NSMaxRange(block.range))
        }
        if inFence { return nil }

        let marker = (String(head[match.range]) as NSString).length
        let rest = text.substring(with: NSRange(location: line.location + marker, length: lineEnd - line.location - marker))
        if rest.trimmingCharacters(in: .whitespaces).isEmpty, location == lineEnd {
            // An empty item inside another steps out a level before the list ends.
            if match.output.7 == nil, let indent = match.output.1, !indent.isEmpty {
                let outdent = ListIndent.removableIndent(of: String(indent))
                return NoteInsertion.Edit(
                    range: NSRange(location: line.location, length: outdent),
                    replacement: "",
                    selection: NSRange(location: location - outdent, length: 0)
                )
            }
            // An empty item: take its marker away and leave a plain line.
            return NoteInsertion.Edit(
                range: NSRange(location: line.location, length: marker),
                replacement: "",
                selection: NSRange(location: line.location, length: 0)
            )
        }

        let next: String
        if let quote = match.output.7 {
            next = String(match.output.6 ?? "") + String(quote)
        } else if let number = match.output.3.flatMap({ Int($0) }) {
            next = String(match.output.1 ?? "") + "\(number + 1)" + String(match.output.4 ?? ".") + " "
        } else {
            let indent = String(match.output.1 ?? "")
            let bullet = String(match.output.2 ?? "-")
            next = indent + bullet + " " + (match.output.5 != nil ? "[ ] " : "")
        }
        let replacement = "\n" + next
        return NoteInsertion.Edit(
            range: NSRange(location: location, length: 0),
            replacement: replacement,
            selection: NSRange(location: location + (replacement as NSString).length, length: 0)
        )
    }
}

/// Tab tucks list items under the one above; Shift-Tab brings them back out.
enum ListIndent {
    /// One level of a list: four spaces, deep enough under both `- ` and `1. ` items.
    static let unit = "    "

    /// How much of `indent` one Shift-Tab takes away: a tab, or up to a level of spaces.
    static func removableIndent(of indent: String) -> Int {
        if indent.hasPrefix("\t") { return 1 }
        return min((unit as NSString).length, indent.prefix { $0 == " " }.count)
    }

    /// The edit for the list items the selection touches, or nil when it touches none, so Tab keeps its
    /// usual meaning. When there's nothing to move, the edit changes nothing.
    static func edit(in text: NSString, selection: NSRange, outdent: Bool) -> NoteInsertion.Edit? {
        let start = min(selection.location, text.length)
        let selection = NSRange(location: start, length: min(selection.length, text.length - start))
        let items = Set(LiveMarkdown(text as String).blocks.compactMap { block -> Int? in
            switch block.kind {
            case .listItem, .task: block.range.location
            default: nil
            }
        })

        let whole = text.lineRange(for: selection)
        var lines: [NSRange] = []
        var location = whole.location
        repeat {
            let line = text.lineRange(for: NSRange(location: location, length: 0))
            lines.append(line)
            location = NSMaxRange(line)
        } while location < NSMaxRange(whole)
        guard lines.contains(where: { items.contains($0.location) }) else { return nil }

        var replacement = ""
        var deltas: [Int] = []
        for line in lines {
            let content = text.substring(with: line)
            guard items.contains(line.location) else {
                replacement += content
                deltas.append(0)
                continue
            }
            if outdent {
                let removable = removableIndent(of: content)
                replacement += String(content.dropFirst(removable))
                deltas.append(-removable)
            } else {
                replacement += unit + content
                deltas.append((unit as NSString).length)
            }
        }

        // Everything on a line moves with it; a cursor inside indentation that's taken away lands at the line's start.
        func moved(_ position: Int) -> Int {
            var shift = 0
            for (index, line) in lines.enumerated() {
                if position < NSMaxRange(line) || index == lines.count - 1 {
                    let column = max(0, position - line.location)
                    return line.location + shift + max(0, column + deltas[index])
                }
                shift += deltas[index]
            }
            return position + shift
        }
        let from = moved(selection.location)
        return NoteInsertion.Edit(
            range: whole,
            replacement: replacement,
            selection: NSRange(location: from, length: max(0, moved(NSMaxRange(selection)) - from))
        )
    }
}

