import Foundation

enum MarkdownRenderSource {
    enum Block: Equatable {
        case markdown(String)
        case displayMath(String)
    }

    static func normalized(_ source: String) -> String {
        sourceChunks(in: source)
            .map { chunk in
                chunk.isCodeFence ? chunk.text : LatexCompatibility.rewritten(normalizeMath(in: chunk.text))
            }
            .joined()
    }

    private static func normalizeMath(in source: String) -> String {
        let dollars = normalizeDelimitedMath(
            in: source,
            opening: "$$",
            closing: "$$",
            replacementOpening: "$$",
            replacementClosing: "$$",
            multiline: true
        )
        let displayLatex = normalizeDelimitedMath(
            in: dollars,
            opening: "\\[",
            closing: "\\]",
            replacementOpening: "$$",
            replacementClosing: "$$",
            multiline: true
        )
        return normalizeDelimitedMath(
            in: displayLatex,
            opening: "\\(",
            closing: "\\)",
            replacementOpening: "$",
            replacementClosing: "$",
            multiline: false
        )
    }

    static func blocks(in source: String) -> [Block] {
        let source = normalized(source)
        var blocks: [Block] = []

        for chunk in sourceChunks(in: source) {
            if chunk.isCodeFence {
                appendMarkdown(chunk.text, to: &blocks)
            } else {
                appendDisplayMathBlocks(from: chunk.text, to: &blocks)
            }
        }
        return blocks.isEmpty ? [.markdown(source)] : blocks
    }

    private static func appendDisplayMathBlocks(from source: String, to blocks: inout [Block]) {
        var cursor = source.startIndex

        while let opening = source.range(of: "$$", range: cursor..<source.endIndex) {
            let bodyStart = opening.upperBound
            guard let closing = source.range(of: "$$", range: bodyStart..<source.endIndex) else {
                break
            }

            appendMarkdown(String(source[cursor..<opening.lowerBound]), to: &blocks)
            let latex = String(source[bodyStart..<closing.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !latex.isEmpty {
                blocks.append(.displayMath(latex))
            }
            cursor = closing.upperBound
        }

        appendMarkdown(String(source[cursor...]), to: &blocks)
    }

    private static func appendMarkdown(_ markdown: String, to blocks: inout [Block]) {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if case .markdown(let existing) = blocks.last {
            blocks[blocks.count - 1] = .markdown(existing + markdown)
        } else {
            blocks.append(.markdown(markdown))
        }
    }

    private struct SourceChunk {
        var text: String
        let isCodeFence: Bool
    }

    private static func sourceChunks(in source: String) -> [SourceChunk] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var chunks: [SourceChunk] = []
        var current = ""
        var currentIsFence = false
        var activeFence: Character?

        func flush() {
            guard !current.isEmpty else { return }
            chunks.append(SourceChunk(text: current, isCodeFence: currentIsFence))
            current = ""
        }

        for (index, lineSlice) in lines.enumerated() {
            let line = String(lineSlice)
            let terminatedLine = line + (index < lines.count - 1 ? "\n" : "")
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let marker = activeFence {
                current += terminatedLine
                if isFenceLine(trimmed, character: marker) {
                    flush()
                    currentIsFence = false
                    activeFence = nil
                }
            } else if let marker = openingFenceCharacter(in: trimmed) {
                flush()
                currentIsFence = true
                current += terminatedLine
                activeFence = marker
            } else {
                current += terminatedLine
            }
        }
        flush()
        return chunks
    }

    private static func openingFenceCharacter(in line: String) -> Character? {
        if isFenceLine(line, character: "`") { return "`" }
        if isFenceLine(line, character: "~") { return "~" }
        return nil
    }

    private static func isFenceLine(_ line: String, character: Character) -> Bool {
        line.prefix { $0 == character }.count >= 3
    }

    private static func normalizeDelimitedMath(
        in source: String,
        opening: String,
        closing: String,
        replacementOpening: String,
        replacementClosing: String,
        multiline: Bool
    ) -> String {
        var result = ""
        var cursor = source.startIndex

        while let openingRange = source.range(of: opening, range: cursor..<source.endIndex) {
            result += source[cursor..<openingRange.lowerBound]
            let bodyStart = openingRange.upperBound
            guard let closingRange = source.range(of: closing, range: bodyStart..<source.endIndex) else {
                result += source[openingRange.lowerBound...]
                return result
            }

            let rawBody = String(source[bodyStart..<closingRange.lowerBound])
            let body = normalizedBody(rawBody, multiline: multiline)
            guard !body.isEmpty else {
                result += source[openingRange.lowerBound..<closingRange.upperBound]
                cursor = closingRange.upperBound
                continue
            }

            result += replacementOpening + body + replacementClosing
            cursor = closingRange.upperBound
        }

        result += source[cursor...]
        return result
    }

    private static func normalizedBody(_ body: String, multiline: Bool) -> String {
        guard multiline else {
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return body
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
