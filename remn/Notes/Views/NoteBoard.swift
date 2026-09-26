import SwiftUI
import SwiftUIMath

/// A folder's notes laid out like pages pinned to a board: the folder's own first,
/// then a stretch of board for each folder inside it, with the pictures and formulas the notes open with.
struct NoteBoard: View {
    let folder: VaultFolder
    /// How many pages a folder inside gets before the rest wait inside it.
    var perSection = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            if !folder.notes.isEmpty {
                NoteBoardPages(notes: folder.notes)
            }
            ForEach(folder.folders.filter { $0.totalNoteCount > 0 }) { child in
                VStack(alignment: .leading, spacing: 16) {
                    NavigationLink(value: NotesRoute.folder(child.path)) {
                        NoteBoardHeader(folder: child)
                    }
                    .buttonStyle(InkRowStyle())
                    let notes = child.allNotes.sorted { $0.modified > $1.modified }
                    NoteBoardPages(notes: Array(notes.prefix(perSection)))
                    if notes.count > perSection {
                        NavigationLink(value: NotesRoute.folder(child.path)) {
                            HStack(spacing: 8) {
                                HandwrittenText("notes.board.more \(notes.count - perSection)")
                                InkIcon(kind: .forward, color: .remnAccent, size: 16)
                            }
                        }
                        .buttonStyle(InkButtonStyle(kind: .quiet, seed: child.path.inkSeed))
                        .padding(.leading, -10)
                    }
                }
            }
        }
    }
}

/// The name of a folder over its stretch of the board.
private struct NoteBoardHeader: View {
    let folder: VaultFolder

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SubjectIconSlot(icon: folder.icon, size: 34)
            HandwrittenText(verbatim: folder.name, weight: 0.5)
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .lineLimit(1)
            HandwrittenText("count.notes \(folder.totalNoteCount)")
                .font(RemnTypography.note)
                .foregroundStyle(Color.remnGraphite)
                .lineLimit(1)
            Spacer(minLength: 8)
            InkIcon(kind: .forward, color: .remnGraphite, size: 16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Pages in columns, each dropped into whichever column is shortest.
private struct NoteBoardPages: View {
    let notes: [NoteSummary]

    var body: some View {
        MasonryLayout(minColumnWidth: 158, spacing: 14) {
            ForEach(notes) { note in
                NavigationLink(value: NotesRoute.note(note.path)) {
                    NoteCard(note: note)
                }
                .buttonStyle(InkRowStyle())
            }
        }
    }
}

/// Columns of different heights, filled the way you'd pin pages up: each goes where there's most room.
struct MasonryLayout: Layout {
    var minColumnWidth: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? minColumnWidth * 2 + spacing
        let placements = arrange(subviews, width: width)
        let height = placements.map { $0.frame.maxY }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for placement in arrange(subviews, width: bounds.width) {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.frame.minX, y: bounds.minY + placement.frame.minY),
                proposal: ProposedViewSize(width: placement.frame.width, height: placement.frame.height)
            )
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [(index: Int, frame: CGRect)] {
        let columns = max(1, Int((width + spacing) / (minColumnWidth + spacing)))
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var heights = [CGFloat](repeating: 0, count: columns)
        return subviews.indices.map { index in
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let column = heights.indices.min { heights[$0] < heights[$1] } ?? 0
            let frame = CGRect(
                x: CGFloat(column) * (columnWidth + spacing),
                y: heights[column],
                width: columnWidth,
                height: size.height
            )
            heights[column] += size.height + spacing
            return (index, frame)
        }
    }
}

/// A note as a page pinned to the board with a strip of tape: what it opens with, its title,
/// the first things it says, and when it was touched.
struct NoteCard: View {
    let note: NoteSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let cover = note.cover, note.isDownloaded {
                NoteCoverView(cover: cover, notePath: note.path, modified: note.modified)
            }
            HandwrittenText(verbatim: note.title, weight: 0.4)
                .font(RemnTypography.display(20, relativeTo: .headline))
                .foregroundStyle(Color.remnInk)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if !note.excerpt.isEmpty {
                HandwrittenText(verbatim: note.excerpt)
                    .font(RemnTypography.display(15.5, relativeTo: .subheadline))
                    .foregroundStyle(Color.remnGraphite)
                    .lineLimit(note.cover == nil ? 8 : 4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                HandwrittenText(verbatim: note.isDownloaded ? RemnFormatters.noteDate(note.modified) : String(localized: "notes.downloading"))
                    .foregroundStyle(Color.remnGraphite.opacity(0.85))
                ForEach(note.tags.prefix(2), id: \.self) { tag in
                    HandwrittenText(verbatim: "#\(tag)")
                        .foregroundStyle(Color.remnAccent)
                }
            }
            .font(RemnTypography.caption)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background {
            InkBox(
                seed: note.path.inkSeed,
                cornerRadius: 5,
                fill: .remnCardPaper,
                outline: .remnInk.opacity(0.8),
                pen: .fine,
                registration: CGSize(width: 0.9, height: 1.2)
            )
        }
        .overlay(alignment: .top) {
            // A strip of tape holding the page up.
            InkPatch(seed: note.path.inkSeed ^ 0x7A9E, cornerRadius: 2)
                .fill(InkPencil.yellow.color.opacity(0.42))
                .frame(width: 46, height: 15)
                .rotationEffect(.degrees(tilt * -3))
                .offset(y: -6)
                .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(tilt))
        .padding(.top, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Pages are pinned up a touch crooked, each its own way.
    private var tilt: Double {
        var random = InkRandom(seed: note.path.inkSeed)
        return Double(random.signed()) * 1.3
    }
}

/// The picture a card opens with: a photo from the note, its first formula, a Typst drawing or code.
private struct NoteCoverView: View {
    @Environment(Vault.self) private var vault
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    let cover: NoteCover
    let notePath: String
    let modified: Date

    @State private var picture: CGImage?

    var body: some View {
        switch cover {
        case .math(let latex):
            ViewThatFits(in: .horizontal) {
                formula(latex, size: 17)
                formula(latex, size: 13)
                formula(latex, size: 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityLabel(Text(verbatim: NoteText.readable(latex: latex)))
        case .code(_, let lines):
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(lines.prefix(5).enumerated()), id: \.offset) { _, line in
                    Text(verbatim: line.isEmpty ? " " : line)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(Color.remnInk.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background {
                InkPatch(seed: notePath.inkSeed ^ 0xC0DE, cornerRadius: 6)
                    .fill(Color.remnInk.opacity(0.05))
            }
            .accessibilityHidden(true)
        case .image, .typst:
            Group {
                if let picture {
                    Image(decorative: picture, scale: displayScale)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .frame(maxWidth: .infinity)
                } else {
                    InkHatch(seed: notePath.inkSeed, spacing: 5)
                        .fill(Color.remnGraphite.opacity(0.18))
                        .clipShape(InkPatch(seed: notePath.inkSeed ^ 0x51, cornerRadius: 6))
                        .frame(height: 70)
                }
            }
            .task(id: cacheKey) { await load() }
            .accessibilityHidden(true)
        }
    }

    private func formula(_ latex: String, size: CGFloat) -> some View {
        Math(LatexCompatibility.rewritten(latex))
            .mathFont(.init(name: .latinModern, size: size))
            .mathTypesettingStyle(.display)
            .mathRenderingMode(.monochrome)
            .foregroundStyle(Color.remnInk)
            .fixedSize()
    }

    private var cacheKey: String {
        "\(notePath)|\(modified.timeIntervalSinceReferenceDate)|\(colorScheme == .dark)|\(displayScale)"
    }

    private func load() async {
        if let cached = NoteCoverCache.shared.image(for: cacheKey) {
            picture = cached
            return
        }
        let loaded: CGImage?
        switch cover {
        case .image(let link):
            guard let url = vault.resolveLink(link, fromNoteAt: notePath) else { return }
            let pixels = 320 * displayScale
            loaded = await Task.detached(priority: .utility) {
                LiveRenderer.downsampledImage(at: url, maxPixelSize: pixels)
            }.value
        case .typst(let source):
            loaded = try? await TypstEngine.shared.render(
                source,
                width: 340,
                fontSize: 11,
                handwritten: true,
                folder: vault.url(for: VaultPath.parent(of: notePath)),
                scale: displayScale,
                dark: colorScheme == .dark
            )
        default:
            loaded = nil
        }
        guard let loaded, !Task.isCancelled else { return }
        NoteCoverCache.shared.store(loaded, for: cacheKey)
        picture = loaded
    }
}

/// Pictures already drawn for cards, so scrolling back doesn't draw them again.
@MainActor
final class NoteCoverCache {
    static let shared = NoteCoverCache()

    private final class Entry {
        let image: CGImage
        init(_ image: CGImage) { self.image = image }
    }

    private let cache: NSCache<NSString, Entry> = {
        let cache = NSCache<NSString, Entry>()
        cache.countLimit = 120
        return cache
    }()

    func image(for key: String) -> CGImage? {
        cache.object(forKey: key as NSString)?.image
    }

    func store(_ image: CGImage, for key: String) {
        cache.setObject(Entry(image), forKey: key as NSString)
    }
}
