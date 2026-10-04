import SwiftUI

extension EnvironmentValues {
    /// Set on the first page of a column that has nowhere to go back to, like the detail of a split layout.
    @Entry var inkeptIsNavigationRoot = false
}

/// The top of a pushed screen: a drawn arrow back to where you came from, and room for one action.
struct InkeptNavigationHeader<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.inkeptIsNavigationRoot) private var isRoot

    let backTitle: String?
    let trailing: Trailing

    init(backTitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.backTitle = backTitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 4) {
            if !isRoot {
                backButton
            }

            Spacer(minLength: 12)

            trailing
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .frame(minHeight: 48)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: 6) {
                InkIcon(kind: .back, color: .inkeptInk, size: 22)
                    .frame(width: 26, height: 44)
                if let backTitle {
                    HandwrittenText(verbatim: backTitle)
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptGraphite)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text("back"))
        .keyboardShortcut("[", modifiers: .command)
    }
}

extension InkeptNavigationHeader where Trailing == EmptyView {
    init(backTitle: String? = nil) {
        self.init(backTitle: backTitle) { EmptyView() }
    }
}

/// The top of a sheet: a quiet way out, what the sheet is, and its one action.
struct SheetHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let leadingTitle: LocalizedStringKey
    let leadingAction: () -> Void
    let trailing: Trailing

    init(
        title: LocalizedStringKey,
        leadingTitle: LocalizedStringKey = "cancel",
        leadingAction: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leadingTitle = leadingTitle
        self.leadingAction = leadingAction
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            SheetGrabber()
            #else
            Color.clear.frame(height: 12)
            #endif
            ZStack {
                HandwrittenText(title, weight: 0.4)
                    .font(InkeptTypography.navigationTitle)
                    .foregroundStyle(Color.inkeptInk)
                    .lineLimit(1)
                    .padding(.horizontal, 96)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Button(action: leadingAction) {
                        HandwrittenText(leadingTitle)
                    }
                    .buttonStyle(InkButtonStyle(kind: .quiet, seed: 12))
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    trailing
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

extension SheetHeader where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        leadingTitle: LocalizedStringKey = "cancel",
        leadingAction: @escaping () -> Void
    ) {
        self.init(title: title, leadingTitle: leadingTitle, leadingAction: leadingAction) { EmptyView() }
    }
}

/// A short pencil stroke where you'd pull the sheet.
struct SheetGrabber: View {
    var body: some View {
        InkLine(seed: 5_150, pen: .bold)
            .fill(Color.inkeptGraphite.opacity(0.55))
            .frame(width: 38, height: 8)
            .padding(.top, 8)
            .padding(.bottom, 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
