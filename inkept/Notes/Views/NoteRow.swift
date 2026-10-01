import SwiftUI

/// A sheet torn from a notebook: ruled, with the red margin down the left. Notes are pages; cards are index cards.
struct NotePageSurface<Content: View>: View {
    let seed: Int
    private let content: Content

    init(seed: Int, @ViewBuilder content: () -> Content) {
        self.seed = seed
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 34)
            .padding(.trailing, 18)
            .padding(.vertical, 15)
            .background {
                ZStack(alignment: .topLeading) {
                    InkBox(
                        seed: seed,
                        cornerRadius: 6,
                        fill: .remnCardPaper,
                        outline: .remnInk.opacity(0.85),
                        pen: .fine,
                        registration: CGSize(width: 0.9, height: 1.2)
                    )
                    GeometryReader { proxy in
                        let rules = Int((proxy.size.height - 12) / 22)
                        ForEach(0..<max(rules, 0), id: \.self) { index in
                            InkLine(seed: seed &+ 40 &+ index, pen: .hairline)
                                .fill(Color.remnGraphite.opacity(0.13))
                                .frame(width: proxy.size.width - 30, height: 4)
                                .offset(x: 22, y: 26 + CGFloat(index) * 22)
                        }
                        InkLine(seed: seed &+ 7, pen: .hairline, vertical: true)
                            .fill(Color.remnAccent.opacity(0.55))
                            .frame(width: 4, height: proxy.size.height - 6)
                            .offset(x: 20, y: 3)
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

/// A note in a list: its title, the first thing it says, its tags and when it was last touched.
struct NoteRow: View {
    let note: NoteSummary
    var showsFolder = false
    /// The icon of the subject the note sits in, shown with its folder.
    var folderIcon: String?

    var body: some View {
        NotePageSurface(seed: note.path.inkSeed) {
            VStack(alignment: .leading, spacing: 5) {
                if showsFolder, !note.folderPath.isEmpty {
                    HStack(spacing: 6) {
                        if let icon = SubjectIcon.named(folderIcon) {
                            SubjectIconView(icon: icon, size: 18)
                        }
                        HandwrittenText(verbatim: note.folderPath.replacingOccurrences(of: "/", with: " / "))
                            .font(RemnTypography.caption)
                            .foregroundStyle(Color.remnGraphite)
                            .lineLimit(1)
                    }
                }
                HandwrittenText(verbatim: note.title, weight: 0.3)
                    .font(RemnTypography.display(23, relativeTo: .title3))
                    .foregroundStyle(Color.remnInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !note.snippet.isEmpty {
                    HandwrittenText(verbatim: note.snippet)
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 10) {
                    HandwrittenText(verbatim: note.isDownloaded ? RemnFormatters.noteDate(note.modified) : String(localized: "notes.downloading"))
                        .foregroundStyle(Color.remnGraphite.opacity(0.85))
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        HandwrittenText(verbatim: "#\(tag)")
                            .foregroundStyle(Color.remnAccent)
                            .lineLimit(1)
                    }
                }
                .font(RemnTypography.caption)
                .padding(.top, 1)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A tag written in red pencil, loosely circled when chosen.
struct TagChip: View {
    let tag: String
    var count: Int?
    var isSelected = false

    var body: some View {
        HStack(spacing: 4) {
            HandwrittenText(verbatim: "#\(tag)")
                .foregroundStyle(isSelected ? Color.remnInk : Color.remnAccent)
            if let count {
                HandwrittenText(verbatim: "\(count)")
                    .foregroundStyle(Color.remnGraphite)
            }
        }
        .font(RemnTypography.note)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            if isSelected {
                InkEllipse(seed: tag.inkSeed, pen: .fine)
                    .fill(Color.remnAccent)
                    .padding(.horizontal, -2)
            } else {
                InkPatch(seed: tag.inkSeed, cornerRadius: 12)
                    .fill(Color.remnAccent.opacity(0.07))
            }
        }
    }
}

/// Lays chips out in lines, wrapping like words.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + lineSpacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
