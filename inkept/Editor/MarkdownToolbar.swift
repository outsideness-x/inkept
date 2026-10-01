import SwiftUI

enum MarkdownInsertion: String, CaseIterable, Identifiable {
    case bold
    case inlineCode
    case codeBlock
    case inlineMath
    case displayMath
    case bullets

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .bold: "editor.tool.bold"
        case .inlineCode: "editor.tool.code"
        case .codeBlock: "editor.tool.block"
        case .inlineMath: "editor.tool.math"
        case .displayMath: "editor.tool.equation"
        case .bullets: "editor.tool.list"
        }
    }

    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .bold: "editor.insert.bold"
        case .inlineCode: "editor.insert.inlineCode"
        case .codeBlock: "editor.insert.codeBlock"
        case .inlineMath: "editor.insert.inlineMath"
        case .displayMath: "editor.insert.displayMath"
        case .bullets: "editor.insert.bullets"
        }
    }

    private var placeholder: String {
        switch self {
        case .bold: "text"
        case .inlineCode, .codeBlock: "code"
        case .inlineMath: "x"
        case .displayMath: "formula"
        case .bullets: "item"
        }
    }

    private var startsOnOwnLine: Bool {
        switch self {
        case .codeBlock, .displayMath, .bullets: true
        case .bold, .inlineCode, .inlineMath: false
        }
    }

    private func wrap(_ inner: String) -> (prefix: String, suffix: String) {
        switch self {
        case .bold: ("**", "**")
        case .inlineCode: ("`", "`")
        case .codeBlock: ("```\n", "\n```")
        case .inlineMath: ("$", "$")
        case .displayMath: ("$$\n", "\n$$")
        case .bullets: ("- ", "")
        }
    }

    /// Wraps the selection (or a placeholder) in Markdown and returns the range to select afterwards,
    /// as character offsets into the new text.
    func apply(to text: inout String, selecting range: Range<Int>?) -> Range<Int> {
        let count = text.count
        let lower = min(max(range?.lowerBound ?? count, 0), count)
        let upper = min(max(range?.upperBound ?? count, lower), count)
        let start = text.index(text.startIndex, offsetBy: lower)
        let end = text.index(text.startIndex, offsetBy: upper)

        let selected = String(text[start..<end])
        let inner = selected.isEmpty ? placeholder : selected
        let (prefix, suffix) = wrap(inner)

        var lead = ""
        if startsOnOwnLine, lower > 0, text[text.index(before: start)] != "\n" {
            lead = "\n"
        }
        text.replaceSubrange(start..<end, with: lead + prefix + inner + suffix)

        let innerStart = lower + lead.count + prefix.count
        return innerStart..<(innerStart + inner.count)
    }
}

/// The Markdown shortcuts, drawn as a row of small cards.
struct MarkdownToolbar: View {
    let insert: (MarkdownInsertion) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(MarkdownInsertion.allCases.enumerated()), id: \.element.id) { index, item in
                    Button { insert(item) } label: {
                        HandwrittenText(item.label)
                            .font(RemnTypography.note)
                            .foregroundStyle(Color.remnInk)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .background {
                                InkBox(
                                    seed: 601 + index * 29,
                                    cornerRadius: 10,
                                    fill: .remnCardPaper,
                                    outline: .remnGraphite,
                                    pen: .hairline,
                                    registration: CGSize(width: 1, height: 1.4)
                                )
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(InkPressStyle())
                    .accessibilityLabel(Text(item.accessibilityLabel))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
    }
}
