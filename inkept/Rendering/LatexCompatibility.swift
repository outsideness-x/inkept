import Foundation

/// LaTeX the math engine doesn't know, rewritten in terms it does.
enum LatexCompatibility {
    /// `\operatorname{rank}` becomes upright letters followed by an operator's thin space; there's no space
    /// before brackets, limits or the end, as LaTeX leaves none there either.
    static func rewritten(_ latex: String) -> String {
        guard latex.contains("\\operatorname") else { return latex }
        let text = latex as NSString
        var result = ""
        var last = 0
        for match in operatorName.matches(in: latex, range: NSRange(location: 0, length: text.length)) {
            result += text.substring(with: NSRange(location: last, length: match.range.location - last))
            let name = text.substring(with: match.range(at: 1))
            let rest = text.substring(from: NSMaxRange(match.range))
            let tight = rest.isEmpty || "([{^_}),.;:|!?".contains(rest.first!)
                || rest.hasPrefix("\\left") || rest.hasPrefix("\\{") || rest.hasPrefix("\\\\")
            result += "\\mathrm{\(name)}" + (tight ? "" : "\\, ")
            last = NSMaxRange(match.range)
        }
        return result + text.substring(from: last)
    }

    private static let operatorName = try! NSRegularExpression(pattern: #"\\operatorname\*?\s*\{([^{}]*)\}\s*"#)
}
