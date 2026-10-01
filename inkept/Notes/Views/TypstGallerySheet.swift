import SwiftUI

/// A ready-made Typst block: a plot, a diagram, a circuit, a timeline.
struct TypstTemplate: Identifiable, Hashable {
    let id: String
    let source: String

    /// Written out one by one so Xcode sees every name that's translated.
    var title: LocalizedStringKey {
        switch id {
        case "annotated": "typst.template.annotated"
        case "plot": "typst.template.plot"
        case "pie": "typst.template.pie"
        case "boxplot": "typst.template.boxplot"
        case "diagram": "typst.template.diagram"
        case "circuit": "typst.template.circuit"
        case "gantt": "typst.template.gantt"
        case "waves": "typst.template.waves"
        case "table": "typst.template.table"
        case "matrix": "typst.template.matrix"
        default: LocalizedStringKey(id)
        }
    }

    /// The templates in the reader's language, from `TypstTemplates/<language>/` in the app.
    static let all: [TypstTemplate] = {
        let language = Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en"
        guard let folder = Bundle.main.url(forResource: "TypstTemplates", withExtension: nil)?
            .appendingPathComponent(language),
            let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        else { return [] }
        return files
            .filter { $0.pathExtension == "typ" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                guard let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let id = url.deletingPathExtension().lastPathComponent
                return TypstTemplate(id: String(id.drop { $0.isNumber || $0 == "-" }), source: source)
            }
    }()
}

/// Picks a Typst block to start from, each drawn by the engine the note will use.
struct TypstGallerySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    let onChoose: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "typst.gallery.title") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HandwrittenText("typst.gallery.message")
                        .font(RemnTypography.note)
                        .foregroundStyle(Color.remnGraphite)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                        blankCard
                        ForEach(TypstTemplate.all) { template in
                            Button { choose(template.source) } label: {
                                TypstTemplateCard(
                                    template: template,
                                    dark: colorScheme == .dark,
                                    scale: displayScale
                                )
                            }
                            .buttonStyle(InkPressStyle())
                        }
                    }
                }
                .padding(20)
                .remnReadableWidth(860)
            }
        }
        .paperBackground()
        .remnSheetFrame(width: 720, height: 780)
        .presentationSizing(.page)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
    }

    private var blankCard: some View {
        Button { choose("") } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: "#set text(…)\n$ E = m c^2 $")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color.remnGraphite)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
                HandwrittenText("typst.template.blank", weight: 0.3)
                    .font(RemnTypography.control)
                    .foregroundStyle(Color.remnInk)
            }
            .padding(16)
            .background {
                InkBox(seed: 9_001, cornerRadius: 14, fill: .remnCardPaper, outline: .remnInk.opacity(0.6), pen: .fine, registration: CGSize(width: 1.2, height: 1.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
    }

    private func choose(_ source: String) {
        onChoose(source)
        dismiss()
    }
}

private struct TypstTemplateCard: View {
    let template: TypstTemplate
    let dark: Bool
    let scale: CGFloat

    @State private var image: CGImage?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let image {
                    Image(decorative: image, scale: scale)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 170)
                } else if failed {
                    InkIcon(kind: .close, color: .remnGraphite, size: 20)
                } else {
                    NotebookDoodle(width: 28)
                        .opacity(0.5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            HandwrittenText(template.title, weight: 0.3)
                .font(RemnTypography.control)
                .foregroundStyle(Color.remnInk)
        }
        .padding(16)
        .background {
            InkBox(seed: template.id.inkSeed, cornerRadius: 14, fill: .remnCardPaper, outline: .remnInk.opacity(0.6), pen: .fine, registration: CGSize(width: 1.2, height: 1.6))
        }
        .contentShape(Rectangle())
        .task(id: dark) {
            do {
                image = try await TypstEngine.shared.render(
                    template.source, width: 330, fontSize: 15, handwritten: true,
                    folder: nil, scale: scale, dark: dark
                )
            } catch {
                failed = true
            }
        }
    }
}
