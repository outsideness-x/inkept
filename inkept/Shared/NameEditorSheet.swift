import SwiftUI

/// Naming a subject, a deck or a folder: one line to write on, and for subjects and folders
/// an icon in front of it, with a few the name brings to mind.
struct NameEditorSheet: View {
    let title: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let initialValue: String
    private let choosesIcon: Bool
    private let onSave: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var icon: String?
    @State private var showIcons = false
    @FocusState private var isFocused: Bool

    init(
        title: LocalizedStringKey,
        actionTitle: LocalizedStringKey = "save",
        initialValue: String = "",
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.initialValue = initialValue
        choosesIcon = false
        self.onSave = { name, _ in onSave(name) }
        _name = State(initialValue: initialValue)
    }

    /// A name with an icon in front of it, as subjects and folders have.
    init(
        title: LocalizedStringKey,
        actionTitle: LocalizedStringKey = "save",
        initialValue: String = "",
        initialIcon: String?,
        onSave: @escaping (String, String?) -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.initialValue = initialValue
        choosesIcon = true
        self.onSave = onSave
        _name = State(initialValue: initialValue)
        _icon = State(initialValue: initialIcon)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: title) {
                dismiss()
            } trailing: {
                Button(action: save) {
                    HandwrittenText(actionTitle, weight: 0.4)
                }
                .buttonStyle(InkButtonStyle(kind: .quiet, seed: 14))
                .disabled(cleanName.isEmpty)
                .opacity(cleanName.isEmpty ? 0.4 : 1)
            }

            HStack(alignment: .center, spacing: 12) {
                if choosesIcon {
                    iconButton
                }
                TextField("name", text: $name)
                    .font(RemnTypography.display(28, relativeTo: .title2))
                    .foregroundStyle(Color.remnInk)
                    .tint(.remnAccent)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit(save)
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) {
                        InkLine(seed: 41, pen: .fine)
                            .fill(Color.remnInk.opacity(0.55))
                            .frame(height: 6)
                            .offset(y: 2)
                    }
            }
            .padding(.horizontal, choosesIcon ? 20 : 26)
            .padding(.top, 22)

            if choosesIcon {
                suggestions
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
            }
            Spacer(minLength: 0)
        }
        .paperBackground()
        .onAppear { isFocused = true }
        .remnSheetFrame(width: choosesIcon ? 480 : 440, height: choosesIcon ? 250 : 170)
        .presentationDetents([.height(choosesIcon ? 296 : 210)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .sheet(isPresented: $showIcons) {
            SubjectIconPicker(name: cleanName, selection: icon) { icon = $0 }
        }
        .sensoryFeedback(.selection, trigger: icon)
    }

    private var iconButton: some View {
        Button { showIcons = true } label: {
            Group {
                if let chosen = SubjectIcon.named(icon) {
                    SubjectIconView(icon: chosen, size: 42)
                } else {
                    EmptyIconSlot(size: 42)
                }
            }
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(icon == nil ? "icon.add" : "icon.title"))
    }

    /// What the name suggests, or a few to start from; the whole catalog is one tap further.
    private var suggestions: some View {
        let suggested = SubjectIcon.suggestions(for: cleanName, limit: 5)
        let shown = suggested.isEmpty ? Array(SubjectIcon.starters.prefix(5)) : suggested
        return HStack(spacing: 0) {
            ForEach(shown) { candidate in
                SubjectIconChoice(icon: candidate, isChosen: candidate.id == icon, size: 30) {
                    icon = candidate.id == icon ? nil : candidate.id
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            Spacer(minLength: 4)
            Button { showIcons = true } label: {
                HandwrittenText("icon.all")
            }
            .buttonStyle(InkButtonStyle(kind: .quiet, seed: 15))
        }
        .animation(.spring(duration: 0.3, bounce: 0.25), value: shown.map(\.id))
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !cleanName.isEmpty else { return }
        onSave(cleanName, icon)
        dismiss()
    }
}
