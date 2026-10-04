import SwiftUI

/// Every icon a subject or a folder can wear, the ones its name brings to mind first.
struct SubjectIconPicker: View {
    @Environment(\.dismiss) private var dismiss
    /// The subject's or folder's name, for suggestions.
    let name: String
    let selection: String?
    let onChoose: (String?) -> Void

    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "icon.title") {
                dismiss()
            } trailing: {
                if selection != nil {
                    Button { choose(nil) } label: {
                        HandwrittenText("icon.remove", weight: 0.4)
                    }
                    .buttonStyle(InkButtonStyle(kind: .quiet, seed: 9_031))
                }
            }
            searchField
                .padding(.horizontal, 24)
                .padding(.top, 8)
            ScrollViewReader { reader in
                VStack(spacing: 0) {
                    if !isSearching {
                        categoryTabs(reader)
                            .padding(.top, 10)
                    }
                    ScrollView {
                        content
                            .padding(.horizontal, 14)
                            .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .paperBackground()
        .inkeptSheetFrame(width: 560, height: 660)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSearching {
                let found = SubjectIcon.search(query)
                if found.isEmpty {
                    HandwrittenText("icon.nothing")
                        .font(InkeptTypography.body)
                        .foregroundStyle(Color.inkeptGraphite)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    grid(found)
                        .padding(.top, 14)
                }
            } else {
                let suggested = SubjectIcon.suggestions(for: name, limit: 12)
                if !suggested.isEmpty {
                    section(Text("icon.suggested \(name)"), icons: suggested)
                }
                ForEach(SubjectIcon.Category.allCases) { category in
                    section(Text(category.title), icons: SubjectIcon.inCategory(category))
                        .id(category)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            InkIcon(kind: .search, color: .inkeptGraphite, size: 19)
            TextField("icon.search", text: $query)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .font(InkeptTypography.display(22, relativeTo: .title3))
                .foregroundStyle(Color.inkeptInk)
                .tint(.inkeptAccent)
            if !query.isEmpty {
                InkIconButton(kind: .close, label: "search.clear", color: .inkeptGraphite, size: 14) { query = "" }
                    .padding(.trailing, -12)
            }
        }
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            InkLine(seed: 9_032, pen: .fine)
                .fill(Color.inkeptInk.opacity(0.5))
                .allowsHitTesting(false)
                .frame(height: 6)
                .offset(y: 2)
        }
    }

    /// One drawing for each part of the catalog, to jump to it.
    private func categoryTabs(_ reader: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(SubjectIcon.Category.allCases) { category in
                Button {
                    withAnimation(.easeOut(duration: 0.3)) { reader.scrollTo(category, anchor: .top) }
                } label: {
                    Group {
                        if let icon = SubjectIcon.named(category.emblem) {
                            SubjectIconView(icon: icon, size: 26)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .contentShape(Rectangle())
                }
                .buttonStyle(InkPressStyle())
                .accessibilityLabel(Text(category.title))
                .help(Text(category.title))
            }
        }
        .padding(.horizontal, 16)
    }

    private func section(_ title: Text, icons: [SubjectIcon]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HandwrittenText(text: title, weight: 0.3)
                .font(InkeptTypography.control)
                .foregroundStyle(Color.inkeptGraphite)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .accessibilityAddTraits(.isHeader)
            grid(icons)
        }
        .padding(.top, 18)
    }

    private func grid(_ icons: [SubjectIcon]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 54, maximum: 72), spacing: 2)], spacing: 2) {
            ForEach(icons) { icon in
                SubjectIconChoice(icon: icon, isChosen: icon.id == selection, size: 38) {
                    choose(icon.id)
                }
            }
        }
    }

    private func choose(_ icon: String?) {
        onChoose(icon)
        dismiss()
    }
}

extension SubjectIcon.Category {
    /// The icon that stands for the whole part of the catalog.
    var emblem: String {
        switch self {
        case .sciences: "atom"
        case .humanities: "palette"
        case .technology: "code"
        case .countries: "globe"
        case .things: "star"
        }
    }
}

/// One icon to choose, loosely circled in red pencil when it's the one chosen.
struct SubjectIconChoice: View {
    let icon: SubjectIcon
    let isChosen: Bool
    var size: CGFloat = 38
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SubjectIconView(icon: icon, size: size)
                .frame(width: size + 16, height: size + 16)
                .background {
                    if isChosen {
                        InkEllipse(seed: icon.id.inkSeed, pen: .fine)
                            .fill(Color.inkeptAccent)
                            .allowsHitTesting(false)
                            .padding(2)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(IconChoiceStyle())
        .accessibilityLabel(Text(verbatim: icon.name))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .help(Text(verbatim: icon.name))
    }
}

/// Presses an icon into the paper; under the pointer it gets a faint pencil wash.
private struct IconChoiceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconChoiceBody(configuration: configuration)
    }
}

private struct IconChoiceBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .background {
                if isHovered {
                    InkPatch(seed: 9_040, cornerRadius: 12)
                        .fill(Color.inkeptInk.opacity(0.05))
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.88 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2, bounce: 0.4), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

/// The place in front of a name where its icon goes: the icon, or a quiet drawing until there is one.
struct SubjectIconSlot: View {
    let icon: String?
    var fallback: InkIconKind = .folder
    var size: CGFloat = 30

    var body: some View {
        Group {
            if let icon = SubjectIcon.named(icon) {
                SubjectIconView(icon: icon, size: size)
            } else {
                InkIcon(kind: fallback, color: .inkeptGraphite.opacity(0.75), size: size * 0.7)
            }
        }
        .frame(width: size, height: size)
    }
}

/// A pencil ring with a plus in it: where an icon can go.
struct EmptyIconSlot: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            InkDashedRing(seed: 9_050)
                .fill(Color.inkeptGraphite.opacity(0.8))
                .allowsHitTesting(false)
                .padding(size * 0.06)
            InkIcon(kind: .plus, color: .inkeptGraphite, size: size * 0.36)
        }
        .frame(width: size, height: size)
    }
}

/// A loop drawn in short dashes.
struct InkDashedRing: Shape {
    var seed: Int
    var pen: InkPen = .fine

    func path(in rect: CGRect) -> Path {
        let loop = InkGeometry.ellipseLoop(in: rect, seed: seed, overshoot: 0)
        var path = Path()
        var dash: [CGPoint] = []
        var travelled: CGFloat = 0
        var drawing = true
        var index = 0
        for (position, point) in loop.enumerated() {
            if position > 0 {
                let previous = loop[position - 1]
                travelled += hypot(point.x - previous.x, point.y - previous.y)
            }
            if drawing { dash.append(point) }
            if drawing, travelled >= 4.2 {
                InkBrush.addStroke(dash, pen: pen, seed: seed &+ index, to: &path)
                dash = []
                travelled = 0
                drawing = false
                index += 1
            } else if !drawing, travelled >= 3.2 {
                drawing = true
                travelled = 0
                dash = [point]
            }
        }
        if drawing, dash.count > 1 {
            InkBrush.addStroke(dash, pen: pen, seed: seed &+ index, to: &path)
        }
        return path
    }
}
