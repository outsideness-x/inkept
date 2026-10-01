import SwiftUI

enum HandmadeDialogRole {
    /// The one thing the dialog is for.
    case normal
    /// Another option.
    case plain
    /// Something that can't be taken back.
    case destructive
    case cancel
}

struct HandmadeDialogAction: Identifiable {
    let id = UUID()
    let title: Text
    let role: HandmadeDialogRole
    let perform: () -> Void

    init(
        _ title: LocalizedStringKey,
        role: HandmadeDialogRole = .normal,
        perform: @escaping () -> Void
    ) {
        self.title = Text(title)
        self.role = role
        self.perform = perform
    }

    init(
        verbatim title: String,
        role: HandmadeDialogRole = .normal,
        perform: @escaping () -> Void
    ) {
        self.title = Text(verbatim: title)
        self.role = role
        self.perform = perform
    }
}

/// A card laid over the screen with a question on it.
private struct HandmadeDialogModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool

    let title: LocalizedStringKey
    let message: Text?
    let actions: [HandmadeDialogAction]

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.38)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { dismiss() }
                            .accessibilityHidden(true)
                            .transition(.opacity)

                        card
                            .padding(.horizontal, 26)
                            .frame(maxWidth: 440)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .scale(scale: 0.94).combined(with: .opacity).combined(with: .offset(y: 12))
                            )
                    }
                    .zIndex(1000)
                    .accessibilityAddTraits(.isModal)
                }
            }
            .animation(
                reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.3, bounce: 0.18),
                value: isPresented
            )
    }

    private var card: some View {
        FlashcardSurface(seed: 771, style: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HandwrittenText(title, weight: 0.5)
                        .font(RemnTypography.display(28, relativeTo: .title2))
                        .foregroundStyle(Color.remnInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let message {
                        HandwrittenText(text: message)
                            .font(RemnTypography.body)
                            .foregroundStyle(Color.remnGraphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .inkWritesOn(duration: 0.4)

                if actions.count > 6 {
                    ScrollView {
                        actionStack
                            .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 380)
                } else {
                    actionStack
                }
            }
        }
    }

    private var actionStack: some View {
        VStack(spacing: 10) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                Button {
                    action.perform()
                    dismiss()
                } label: {
                    HandwrittenText(text: action.title)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(style(for: action.role, index: index))
                .keyboardShortcut(shortcut(for: action))
            }
        }
    }

    private func style(for role: HandmadeDialogRole, index: Int) -> InkButtonStyle {
        switch role {
        case .normal: InkButtonStyle(kind: .primary, seed: 850 + index)
        case .plain: InkButtonStyle(kind: .secondary, seed: 850 + index)
        case .destructive: InkButtonStyle(kind: .destructive, seed: 850 + index)
        case .cancel: InkButtonStyle(kind: .quiet, seed: 850 + index)
        }
    }

    private func shortcut(for action: HandmadeDialogAction) -> KeyboardShortcut? {
        switch action.role {
        case .cancel:
            return .cancelAction
        case .normal where actions.filter({ $0.role == .normal }).count == 1:
            return .defaultAction
        default:
            return nil
        }
    }

    private func dismiss() {
        isPresented = false
    }
}

extension View {
    func handmadeDialog(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: Text? = nil,
        actions: [HandmadeDialogAction]
    ) -> some View {
        modifier(
            HandmadeDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                actions: actions
            )
        )
    }
}

extension View {
    /// On the Mac a right click offers the same actions as the drawn "more" button, in a native menu.
    @ViewBuilder
    func remnContextMenu(_ actions: [HandmadeDialogAction]) -> some View {
        #if os(macOS)
        contextMenu {
            ForEach(actions) { action in
                Button(role: action.role == .destructive ? .destructive : nil, action: action.perform) {
                    action.title
                }
            }
        }
        #else
        self
        #endif
    }
}
