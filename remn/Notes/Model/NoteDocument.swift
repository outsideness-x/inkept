import Foundation

/// One note: its front matter and the Markdown you write.
struct NoteDocument: Equatable, Sendable {
    var frontMatter: FrontMatter
    var body: String

    init(frontMatter: FrontMatter = FrontMatter(), body: String = "") {
        self.frontMatter = frontMatter
        self.body = body
    }

    init(text: String) {
        let text = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard text.hasPrefix("---\n") else {
            self.init(body: text)
            return
        }
        let afterOpening = text.index(text.startIndex, offsetBy: 4)
        var lineStart = afterOpening
        while true {
            let lineEnd = text[lineStart...].firstIndex(of: "\n") ?? text.endIndex
            let line = text[lineStart..<lineEnd]
            if line == "---" || line == "..." {
                let yaml = String(text[afterOpening..<lineStart])
                var bodyStart = lineEnd < text.endIndex ? text.index(after: lineEnd) : lineEnd
                // One blank line after the front matter belongs to it, not to the note.
                if bodyStart < text.endIndex, text[bodyStart] == "\n" {
                    bodyStart = text.index(after: bodyStart)
                }
                self.init(frontMatter: FrontMatter(yaml: yaml), body: String(text[bodyStart...]))
                return
            }
            guard lineEnd < text.endIndex else { break }
            lineStart = text.index(after: lineEnd)
        }
        self.init(body: text)
    }

    var text: String {
        guard !frontMatter.isEmpty else { return body }
        return "---\n\(frontMatter.yaml)\n---\n\n\(body)"
    }

    /// Tags from the front matter and `#tags` written in the text.
    var allTags: [String] {
        FrontMatter.cleaned(frontMatter.tags + NoteText.inlineTags(in: body))
    }
}

enum NoteText {
    /// `#tags` in running text; headings (`# `), code and links don't count.
    static func inlineTags(in body: String) -> [String] {
        var tags: [String] = []
        var inFence = false
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            guard !inFence else { continue }
            let text = String(line)
            let pattern = #/(?:^|[\s(])#([\p{L}\p{N}_\/-]*[\p{L}_][\p{L}\p{N}_\/-]*)/#
            for match in text.matches(of: pattern) {
                tags.append(String(match.output.1))
            }
        }
        return tags
    }

    /// A line of Markdown as it reads: formulas written out, links as their words, emphasis marks gone.
    static func plain(_ line: String) -> String {
        readableMath(in: line)
            .replacingOccurrences(of: #"!\[\[[^\]]*\]\]|!\[[^\]]*\]\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[\[([^\]|]+)\|([^\]]+)\]\]"#, with: "$2", options: .regularExpression)
            .replacingOccurrences(of: #"\[\[([^\]#|]+)(#[^\]]*)?\]\]"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\*\*|__|==|~~|`"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?<![\w*])[*_](?=\S)|(?<=\S)[*_](?![\w*])"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// The first line worth showing under a note's title, without Markdown punctuation.
    static func snippet(of body: String, limit: Int = 160) -> String {
        var inFence = false
        for line in body.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            // Headings usually repeat the title, so the snippet starts with what's under them.
            let isHeading = trimmed.range(of: #"^#{1,6}\s"#, options: .regularExpression) != nil
            guard !inFence, !trimmed.isEmpty, !isHeading, trimmed != "$$", !trimmed.hasPrefix("!["), trimmed != "---" else {
                continue
            }
            let clean = plain(
                trimmed.replacingOccurrences(of: #"^(#{1,6}|>|[-*+]|\d+\.)\s+(\[[ xX]\]\s+)?"#, with: "", options: .regularExpression)
            )
            guard !clean.isEmpty else { continue }
            return clean.count > limit ? String(clean.prefix(limit)) + "…" : clean
        }
        return ""
    }
}
