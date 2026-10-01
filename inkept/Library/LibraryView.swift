import SwiftData
import SwiftUI

/// What the detail column of the split layout shows.
enum LibraryDestination: Hashable {
    case subject(UUID)
    case search
}

/// Every subject on one page. On iPhone it is the first screen; on iPad and the Mac it is the sidebar,
/// and choosing a subject opens it beside the list instead of on top of it.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @Query private var cards: [Flashcard]
    @Query private var sessions: [StudySessionRecord]

    /// Present when the library is the sidebar of a split layout.
    var selection: Binding<LibraryDestination?>?

    @State private var showCreate = false
    @State private var manageSubject: SubjectModel?
    @State private var renameSubject: SubjectModel?
    @State private var iconSubject: SubjectModel?
    @State private var deleteSubject: SubjectModel?

    private var isSidebar: Bool { selection != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if subjects.isEmpty {
                    QuietEmptyState(
                        title: "library.empty",
                        actionTitle: "subject.make",
                        action: { showCreate = true }
                    )
                    .padding(.top, 36)
                } else {
                    TimelineView(.everyMinute) { timeline in
                        today(at: timeline.date)
                    }
                    .padding(.top, 2)
                    subjectList
                        .padding(.top, isSidebar ? 22 : 30)
                    newSubjectButton
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, isSidebar ? 16 : 22)
            .padding(.top, topInset)
            .padding(.bottom, 40)
            .remnReadableWidth()
        }
        .scrollIndicators(isSidebar ? .never : .automatic)
        .paperBackground()
        .remnHidesSystemBar()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if !cards.isEmpty {
                    bottomActions
                }
                if !isSidebar {
                    @Bindable var appState = appState
                    RemnTabBar(selection: $appState.section)
                }
            }
            .background(alignment: .bottom) { PaperFade() }
        }
        .sheet(isPresented: $showCreate) {
            NameEditorSheet(title: "subject.new", initialIcon: nil) { name, icon in
                let order = (subjects.map(\.manualSortOrder).max() ?? -1) + 1
                let subject = SubjectModel(name: name, manualSortOrder: order, icon: icon)
                context.insert(subject)
                save()
                selection?.wrappedValue = .subject(subject.id)
            }
        }
        .sheet(item: $renameSubject) { subject in
            NameEditorSheet(title: "subject.rename", initialValue: subject.name, initialIcon: subject.icon) { name, icon in
                subject.name = name
                subject.icon = icon
                subject.updatedAt = .now
                save()
            }
        }
        .sheet(item: $iconSubject) { subject in
            SubjectIconPicker(name: subject.name, selection: subject.icon) { icon in
                subject.icon = icon
                subject.updatedAt = .now
                save()
            }
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageSubject != nil },
                set: { if !$0 { manageSubject = nil } }
            ),
            title: "subject",
            message: Text(verbatim: manageSubject?.name ?? ""),
            actions: subjectActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteSubject != nil },
                set: { if !$0 { deleteSubject = nil } }
            ),
            title: "subject.delete.title",
            message: Text("subject.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteSubject {
                        if selection?.wrappedValue == .subject(deleteSubject.id) {
                            selection?.wrappedValue = nil
                        }
                        context.delete(deleteSubject)
                        save()
                    }
                    deleteSubject = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteSubject = nil }
            ]
        )
        .onChange(of: appState.requestedCommand) { _, command in
            guard command == .newSubject else { return }
            appState.requestedCommand = nil
            showCreate = true
        }
    }

    /// Room for the window buttons, which sit on the paper at the top of the sidebar on the Mac.
    private var topInset: CGFloat {
        isSidebar && RemnPlatform.isMac ? 30 : 6
    }

    @ViewBuilder
    private var header: some View {
        if let selection {
            @Bindable var appState = appState
            SidebarHeader(
                section: $appState.section,
                searchSelected: selection.wrappedValue == .search,
                onSearch: { selection.wrappedValue = .search }
            )
        } else {
            phoneHeader
        }
    }

    private var phoneHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            HandwrittenText("remn", weight: 1)
                .font(RemnTypography.wordmark)
                .foregroundStyle(Color.remnInk)
                .accessibilityAddTraits(.isHeader)
                .inkWritesOn(duration: 0.55)
            Spacer()
            NavigationLink { SearchView() } label: {
                InkIcon(kind: .search, size: 23)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(Text("search"))
            NavigationLink { SettingsView() } label: {
                InkIcon(kind: .settings, size: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(Text("settings"))
        }
        .padding(.trailing, -10)
    }

    @ViewBuilder
    private func today(at date: Date) -> some View {
        let due = cards.dueTodayCount(now: date)
        let fresh = cards.count { $0.state == .new }
        Group {
            if due > 0 {
                HandwrittenText("home.dueToday \(due)")
            } else if fresh > 0 {
                HandwrittenText("home.newReady \(fresh)")
            } else if let next = cards.map(\.due).filter({ $0 > date }).min() {
                HandwrittenText("home.caughtUp \(next.formatted(.relative(presentation: .named)))")
            } else {
                HandwrittenText("home.noCards")
            }
        }
        .font(isSidebar ? RemnTypography.note : RemnTypography.body)
        .foregroundStyle(Color.remnGraphite)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var subjectList: some View {
        if let selection {
            LazyVStack(spacing: 6) {
                ForEach(subjects, id: \.id) { subject in
                    let isSelected = selection.wrappedValue == .subject(subject.id) && !appState.showsSettings
                    Button {
                        selection.wrappedValue = .subject(subject.id)
                        appState.showsSettings = false
                    } label: {
                        LibraryRow(
                            title: subject.name,
                            dueCount: subject.cards.dueTodayCount(),
                            totalCount: subject.cards.count,
                            compact: true,
                            icon: .subject(subject.icon)
                        )
                        .padding(.leading, 14)
                        .padding(.trailing, 40)
                    }
                    .buttonStyle(SidebarRowStyle(isSelected: isSelected, seed: subject.id.inkSeed))
                    .overlay(alignment: .trailing) {
                        InkIconButton(kind: .more, label: "actions", color: .remnGraphite, size: 18) {
                            manageSubject = subject
                        }
                        .padding(.trailing, 2)
                    }
                    .remnContextMenu(subjectActions(for: subject))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                    if index > 0 {
                        InkDivider(seed: subject.id.inkSeed)
                    }
                    HStack(spacing: 0) {
                        NavigationLink {
                            SubjectDetailView(subject: subject)
                        } label: {
                            LibraryRow(
                                title: subject.name,
                                dueCount: subject.cards.dueTodayCount(),
                                totalCount: subject.cards.count,
                                icon: .subject(subject.icon)
                            )
                        }
                        .buttonStyle(InkRowStyle())

                        InkIconButton(kind: .more, label: "actions", color: .remnGraphite, size: 20) {
                            manageSubject = subject
                        }
                        .padding(.trailing, -10)
                    }
                }
            }
        }
    }

    private var newSubjectButton: some View {
        Button { showCreate = true } label: {
            HStack(spacing: 8) {
                InkIcon(kind: .plus, color: .remnAccent, size: 18)
                HandwrittenText("subject.new")
            }
        }
        .buttonStyle(InkButtonStyle(kind: .quiet, seed: 44))
        .padding(.leading, -10)
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            if let activeSession {
                Button {
                    appState.presentedSession = activeSession
                } label: {
                    HandwrittenText("study.continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .secondary, seed: 72))
            }
            Button {
                appState.prepareStudy()
            } label: {
                HStack(spacing: 14) {
                    StackedCardsDoodle(
                        ink: .remnOnAccent,
                        accent: .remnOnAccent,
                        paper: .remnAccent,
                        width: 36
                    )
                    HandwrittenText("study", weight: 0.6)
                    Spacer()
                    InkIcon(kind: .forward, color: .remnOnAccent, size: 22)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle(kind: .primary, seed: 8))
        }
        .padding(.horizontal, isSidebar ? 14 : 20)
        .padding(.top, 14)
        .padding(.bottom, isSidebar ? max(14, RemnPlatform.bottomButtonPadding) : 4)
        .remnReadableWidth(600)
    }

    private var activeSession: StudySessionRecord? {
        sessions.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    private var subjectActions: [HandmadeDialogAction] {
        guard let subject = manageSubject else { return [] }
        return subjectActions(for: subject) + [
            HandmadeDialogAction("cancel", role: .cancel) { manageSubject = nil }
        ]
    }

    private func subjectActions(for subject: SubjectModel) -> [HandmadeDialogAction] {
        var actions = [
            HandmadeDialogAction("rename", role: .plain) {
                manageSubject = nil
                renameSubject = subject
            },
            HandmadeDialogAction("icon.choose", role: .plain) {
                manageSubject = nil
                iconSubject = subject
            },
        ]
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            if index > subjects.startIndex {
                actions.append(
                    HandmadeDialogAction("move.up", role: .plain) {
                        move(subject, by: -1)
                    }
                )
            }
            if index < subjects.index(before: subjects.endIndex) {
                actions.append(
                    HandmadeDialogAction("move.down", role: .plain) {
                        move(subject, by: 1)
                    }
                )
            }
        }
        actions.append(
            HandmadeDialogAction("delete", role: .destructive) {
                manageSubject = nil
                deleteSubject = subject
            }
        )
        return actions
    }

    private func move(_ subject: SubjectModel, by offset: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subject.id }) else { return }
        let destination = index + offset
        guard subjects.indices.contains(destination) else { return }
        let other = subjects[destination]
        let oldOrder = subject.manualSortOrder
        subject.manualSortOrder = other.manualSortOrder
        other.manualSortOrder = oldOrder
        save()
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }
}

/// Paper that fades in behind controls pinned to the bottom of a scrolling page.
struct PaperFade: View {
    var body: some View {
        PaperBackground()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.28),
                        .init(color: .black, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}
