import SwiftUI

/// The pens along the bottom of a note: headings, emphasis, lists, code, formulas.
struct NoteToolbar: View {
    let controller: LiveEditorController
    var onInsertTypst: (() -> Void)?
    var onInsertImage: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            InkLine(seed: 8_401, pen: .hairline)
                .fill(Color.remnInk.opacity(0.2))
                .frame(height: 6)
                .padding(.horizontal, 12)
            HStack(spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        tool("H", label: "insert.heading", shortcut: nil) { controller.apply(.heading) }
                        tool("B", label: "insert.bold", weight: 0.9, shortcut: "b") { controller.apply(.bold) }
                        tool("I", label: "insert.italic", slanted: true, shortcut: "i") { controller.apply(.italic) }
                        tool("S", label: "insert.strikethrough", struck: true, shortcut: nil) { controller.apply(.strikethrough) }
                        tool("==", label: "insert.highlight", shortcut: nil) { controller.apply(.highlight) }
                        separator
                        iconTool(.list, label: "insert.bullets") { controller.apply(.bullets) }
                        tool("1.", label: "insert.numbers", shortcut: nil) { controller.apply(.numbers) }
                        iconTool(.check, label: "insert.tasks") { controller.apply(.tasks) }
                        tool("❝", label: "insert.quote", shortcut: nil) { controller.apply(.quote) }
                        separator
                        tool("x²", label: "insert.inlineMath", shortcut: nil) { controller.apply(.inlineMath) }
                        tool("∑", label: "insert.mathBlock", shortcut: nil) { controller.apply(.mathBlock) }
                        tool("</>", label: "insert.code", shortcut: nil) { controller.apply(.inlineCode) }
                        tool("{ }", label: "insert.codeBlock", shortcut: nil) { controller.apply(.codeBlock) }
                        if let onInsertTypst {
                            tool("typst", label: "insert.typst", shortcut: nil, action: onInsertTypst)
                        }
                        if let onInsertImage {
                            iconTool(.picture, label: "insert.image", action: onInsertImage)
                        }
                        separator
                        tool("—", label: "insert.rule", shortcut: nil) { controller.apply(.rule) }
                        tool("▦", label: "insert.table", shortcut: nil) { controller.apply(.table) }
                        tool("[ ]", label: "insert.link", shortcut: "k") { controller.apply(.link) }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)

                if controller.hasSelection {
                    Button { controller.makeCardFromSelection() } label: {
                        HStack(spacing: 6) {
                            InkIcon(kind: .card, color: .remnOnAccent, size: 18)
                            HandwrittenText("notes.makeCard.short", weight: 0.4)
                                .font(RemnTypography.note)
                                .foregroundStyle(Color.remnOnAccent)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 38)
                        .background {
                            InkBox(seed: 8_420, cornerRadius: 11, fill: .remnAccent, outline: .remnInk, pen: .fine, registration: CGSize(width: 1.2, height: 1.6))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(InkPressStyle())
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .padding(.trailing, 10)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }

                #if os(iOS)
                InkIconButton(kind: .down, label: "done", color: .remnGraphite, size: 18) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .padding(.trailing, 4)
                #endif
            }
            .animation(.spring(duration: 0.25, bounce: 0.3), value: controller.hasSelection)
        }
        .background { PaperBackground() }
    }

    private var separator: some View {
        InkLine(seed: 8_402, pen: .hairline, vertical: true)
            .fill(Color.remnGraphite.opacity(0.4))
            .frame(width: 4, height: 22)
            .padding(.horizontal, 2)
    }

    private func tool(
        _ glyph: String,
        label: LocalizedStringKey,
        weight: Double = 0,
        slanted: Bool = false,
        struck: Bool = false,
        shortcut: KeyEquivalent?,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            HandwrittenText(verbatim: glyph, weight: weight)
                .font(RemnTypography.display(19, relativeTo: .body))
                .foregroundStyle(Color.remnInk)
                .transformEffect(slanted ? CGAffineTransform(a: 1, b: 0, c: -0.22, d: 1, tx: 3, ty: 0) : .identity)
                .overlay {
                    if struck {
                        InkLine(seed: 8_403, pen: .fine).fill(Color.remnInk).frame(height: 4)
                    }
                }
                .padding(.horizontal, glyph.count > 3 ? 8 : 2)
                .frame(minWidth: 38, minHeight: 38)
                .background {
                    InkBox(seed: glyph.inkSeed, cornerRadius: 10, fill: .remnCardPaper, outline: .remnGraphite.opacity(0.8), pen: .hairline, registration: CGSize(width: 0.8, height: 1.1))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(label))
        return Group {
            if let shortcut {
                button.keyboardShortcut(shortcut, modifiers: .command)
            } else {
                button
            }
        }
    }

    private func iconTool(_ kind: InkIconKind, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            InkIcon(kind: kind, color: .remnInk, size: 18)
                .frame(width: 38, height: 38)
                .background {
                    InkBox(seed: kind.rawValue &* 97, cornerRadius: 10, fill: .remnCardPaper, outline: .remnGraphite.opacity(0.8), pen: .hairline, registration: CGSize(width: 0.8, height: 1.1))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(label))
    }
}

/// Every face a note can be set in, each written in itself.
struct FontPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: NoteFont

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "notes.font", leadingTitle: "done") { dismiss() }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                    ForEach(NoteFont.allCases) { font in
                        let chosen = font == selection
                        Button { selection = font } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(verbatim: "Aa Бб")
                                        .font(font.font(size: 30))
                                        .foregroundStyle(Color.remnInk)
                                    Spacer()
                                    if chosen {
                                        InkIcon(kind: .check, color: .remnAccent, size: 18)
                                    }
                                }
                                Text(verbatim: font.displayName)
                                    .font(font.font(size: 17))
                                    .foregroundStyle(Color.remnInk)
                                HandwrittenText(font.note)
                                    .font(RemnTypography.caption)
                                    .foregroundStyle(Color.remnGraphite)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background {
                                InkBox(
                                    seed: font.rawValue.inkSeed,
                                    cornerRadius: 14,
                                    fill: .remnCardPaper,
                                    outline: chosen ? .remnAccent : .remnInk.opacity(0.6),
                                    pen: chosen ? .pen : .fine,
                                    registration: CGSize(width: 1.2, height: 1.6)
                                )
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(InkPressStyle())
                        .accessibilityAddTraits(chosen ? .isSelected : [])
                    }
                }
                .padding(20)
                .remnReadableWidth(720)
            }
        }
        .paperBackground()
        .remnSheetFrame(width: 620, height: 700)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// A note's tags: tick the ones it has, or write a new one.
struct TagEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Vault.self) private var vault
    @Binding var tags: [String]
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "notes.tags", leadingTitle: "done") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        HandwrittenText(verbatim: "#")
                            .font(RemnTypography.display(26, relativeTo: .title2))
                            .foregroundStyle(Color.remnAccent)
                        TextField("notes.tags.new", text: $draft)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                            .font(RemnTypography.display(24, relativeTo: .title3))
                            .foregroundStyle(Color.remnInk)
                            .tint(.remnAccent)
                            .focused($focused)
                            .onSubmit(addDraft)
                        if !draft.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: addDraft) { HandwrittenText("add") }
                                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 8_501))
                        }
                    }
                    .overlay(alignment: .bottom) {
                        InkLine(seed: 8_502, pen: .fine)
                            .fill(Color.remnInk.opacity(0.55))
                            .frame(height: 6)
                            .offset(y: 6)
                    }

                    FlowLayout(spacing: 8, lineSpacing: 10) {
                        ForEach(allTags, id: \.self) { tag in
                            let isOn = tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
                            Button {
                                toggle(tag)
                            } label: {
                                TagChip(tag: tag, isSelected: isOn)
                            }
                            .buttonStyle(InkPressStyle())
                            .accessibilityAddTraits(isOn ? .isSelected : [])
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(24)
                .remnReadableWidth(600)
            }
        }
        .paperBackground()
        .remnSheetFrame(width: 480, height: 520)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .sensoryFeedback(.selection, trigger: tags)
    }

    private var allTags: [String] {
        FrontMatter.cleaned(tags + vault.tags.map(\.tag))
    }

    private func toggle(_ tag: String) {
        if let index = tags.firstIndex(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            tags.remove(at: index)
        } else {
            tags.append(tag)
        }
    }

    private func addDraft() {
        let clean = FrontMatter.cleaned([draft])
        guard let tag = clean.first else { return }
        if !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            tags.append(tag)
        }
        draft = ""
        focused = true
    }
}
