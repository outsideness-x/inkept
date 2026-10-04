import SwiftUI

/// A folder's notes by the day they were written, newest first, strung along a pencil line;
/// above them, the last twelve weeks, each day shaded by how much was written on it.
struct NoteTimeline: View {
    @Environment(Vault.self) private var vault
    let folder: VaultFolder

    var body: some View {
        let notes = folder.allNotes.sorted { $0.written > $1.written }
        let days = Self.days(of: notes)
        VStack(alignment: .leading, spacing: 0) {
            NoteRhythm(notes: notes)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(days, id: \.day) { entry in
                    TimelineDay(day: entry.day, notes: entry.notes, isLast: entry.day == days.last?.day, iconFor: icon(for:))
                }
            }
            .padding(.top, 26)
        }
    }

    private func icon(for note: NoteSummary) -> String? {
        vault.root.icon(forFolder: note.folderPath)
    }

    static func days(of notes: [NoteSummary], calendar: Calendar = .current) -> [(day: Date, notes: [NoteSummary])] {
        var days: [(day: Date, notes: [NoteSummary])] = []
        for note in notes {
            let day = calendar.startOfDay(for: note.written)
            if days.last?.day == day {
                days[days.count - 1].notes.append(note)
            } else {
                days.append((day, [note]))
            }
        }
        return days
    }
}

/// One day on the line: a dot, the day's name, and what was written.
private struct TimelineDay: View {
    let day: Date
    let notes: [NoteSummary]
    let isLast: Bool
    let iconFor: (NoteSummary) -> String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HandwrittenText(verbatim: title, weight: 0.4)
                .font(InkeptTypography.control)
                .foregroundStyle(isToday ? Color.inkeptAccent : Color.inkeptInk)
                .accessibilityAddTraits(.isHeader)
            ForEach(notes) { note in
                NavigationLink(value: NotesRoute.note(note.path)) {
                    TimelineEntry(note: note, icon: iconFor(note))
                }
                .buttonStyle(InkRowStyle())
            }
        }
        .padding(.leading, 30)
        .padding(.bottom, 22)
        .background(alignment: .topLeading) {
            // The line runs down the left edge, from this day's dot to the next.
            ZStack(alignment: .top) {
                if !isLast {
                    InkLine(seed: seed, pen: .hairline, vertical: true)
                        .fill(Color.inkeptInk.opacity(0.3))
                        .frame(width: 6)
                        .padding(.top, 16)
                }
                InkEllipse(seed: seed, pen: .fine)
                    .fill(isToday ? Color.inkeptAccent : Color.inkeptInk)
                    .background(Circle().fill(isToday ? Color.inkeptAccent.opacity(0.25) : Color.inkeptCardPaper).padding(1))
                    .frame(width: 13, height: 13)
                    .padding(.top, 9)
            }
            .frame(width: 16)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var seed: Int {
        Int(day.timeIntervalSinceReferenceDate / 86_400)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "notes.timeline.today") }
        if calendar.isDateInYesterday(day) { return String(localized: "notes.yesterday") }
        let days = calendar.dateComponents([.day], from: day, to: calendar.startOfDay(for: .now)).day ?? 0
        if days < 7 { return day.formatted(.dateTime.weekday(.wide)).lowercased() }
        if calendar.isDate(day, equalTo: .now, toGranularity: .year) {
            return day.formatted(.dateTime.day().month(.wide)).lowercased()
        }
        return day.formatted(.dateTime.day().month(.wide).year()).lowercased()
    }
}

/// A note on the timeline: its subject's icon, its title, the first thing it says and where it lives.
private struct TimelineEntry: View {
    let note: NoteSummary
    let icon: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SubjectIconSlot(icon: icon, fallback: .list, size: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                HandwrittenText(verbatim: note.title, weight: 0.3)
                    .font(InkeptTypography.display(21, relativeTo: .headline))
                    .foregroundStyle(Color.inkeptInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !note.snippet.isEmpty {
                    HandwrittenText(verbatim: note.snippet)
                        .font(InkeptTypography.note)
                        .foregroundStyle(Color.inkeptGraphite)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                HStack(spacing: 8) {
                    HandwrittenText(verbatim: note.written.formatted(date: .omitted, time: .shortened))
                    if !note.folderPath.isEmpty {
                        HandwrittenText(verbatim: note.folderPath.replacingOccurrences(of: "/", with: " / "))
                            .lineLimit(1)
                    }
                }
                .font(InkeptTypography.caption)
                .foregroundStyle(Color.inkeptGraphite.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Twelve weeks of days, a square each, shaded in red pencil by how many notes were written on it,
/// with the months along the top and every other weekday down the side.
struct NoteRhythm: View {
    let notes: [NoteSummary]
    var weeks = 12

    private static let side: CGFloat = 13
    private static let gap: CGFloat = 4
    private static let labelHeight: CGFloat = 16

    var body: some View {
        let calendar = Calendar.current
        let counts = Dictionary(grouping: notes) { calendar.startOfDay(for: $0.written) }.mapValues(\.count)
        let columns = Self.columns(weeks: weeks, calendar: calendar)
        let months = Self.monthLabels(for: columns, calendar: calendar)
        let total = columns.joined().compactMap { $0 }.reduce(0) { $0 + (counts[$1] ?? 0) }
        VStack(alignment: .leading, spacing: 10) {
            HandwrittenText("notes.timeline.rhythm \(total)")
                .font(InkeptTypography.note)
                .foregroundStyle(Color.inkeptGraphite)
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .trailing, spacing: Self.gap) {
                    Color.clear.frame(width: 1, height: Self.labelHeight)
                    ForEach(0..<7, id: \.self) { row in
                        label(Self.weekdayLabel(row: row, calendar: calendar) ?? "")
                            .frame(height: Self.side)
                    }
                }
                HStack(alignment: .top, spacing: Self.gap) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: Self.gap) {
                            label(months[index] ?? "")
                                .fixedSize()
                                .frame(width: Self.side, height: Self.labelHeight, alignment: .bottomLeading)
                            ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                square(for: day, count: day.flatMap { counts[$0] } ?? 0)
                            }
                        }
                    }
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func label(_ text: String) -> some View {
        HandwrittenText(verbatim: text)
            .font(.custom("Neucha", fixedSize: 12.5))
            .foregroundStyle(Color.inkeptGraphite)
    }

    @ViewBuilder
    private func square(for day: Date?, count: Int) -> some View {
        let seed = day.map { Int($0.timeIntervalSinceReferenceDate / 86_400) } ?? 0
        ZStack {
            if let day {
                if count > 0 {
                    InkPatch(seed: seed, cornerRadius: 3)
                        .fill(Color.inkeptAccent.opacity(min(0.3 + Double(count) * 0.22, 0.95)))
                } else {
                    InkPatch(seed: seed, cornerRadius: 3)
                        .fill(Color.inkeptInk.opacity(0.06))
                }
                if Calendar.current.isDateInToday(day) {
                    InkRoundedRect(seed: seed, cornerRadius: 3, pen: .hairline)
                        .fill(Color.inkeptInk)
                }
            }
        }
        .frame(width: Self.side, height: Self.side)
        .allowsHitTesting(false)
    }

    /// The days of the last `weeks` weeks, a column a week, ending with this one; days still to come are empty.
    nonisolated static func columns(weeks: Int, calendar: Calendar = .current, now: Date = .now) -> [[Date?]] {
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let intoWeek = (weekday - calendar.firstWeekday + 7) % 7
        guard let thisWeek = calendar.date(byAdding: .day, value: -intoWeek, to: today),
              let first = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: thisWeek)
        else { return [] }
        return (0..<weeks).map { week in
            (0..<7).map { offset -> Date? in
                guard let day = calendar.date(byAdding: .day, value: week * 7 + offset, to: first), day <= today else { return nil }
                return day
            }
        }
    }

    /// Each month's short name over the week it starts in, and the first week's month over the first
    /// week — unless the next name would run into it.
    nonisolated static func monthLabels(for columns: [[Date?]], calendar: Calendar = .current, locale: Locale = .current) -> [String?] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("LLL")
        func name(_ date: Date) -> String {
            formatter.string(from: date).lowercased(with: locale).trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
        var labels = columns.map { week -> String? in
            week.compactMap { $0 }.first { calendar.component(.day, from: $0) == 1 }.map(name)
        }
        if let first = columns.first?.compactMap({ $0 }).first, !labels.prefix(3).contains(where: { $0 != nil }) {
            labels[0] = name(first)
        }
        return labels
    }

    /// Monday, Wednesday and Friday, wherever the week starts; the other rows go unnamed.
    nonisolated static func weekdayLabel(row: Int, calendar: Calendar = .current) -> String? {
        let weekday = (calendar.firstWeekday - 1 + row) % 7 + 1
        guard [2, 4, 6].contains(weekday) else { return nil }
        return calendar.shortStandaloneWeekdaySymbols[weekday - 1].lowercased()
    }
}
