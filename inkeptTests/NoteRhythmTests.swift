import Foundation
import Testing
@testable import inkept

struct NoteRhythmTests {
    /// Weeks from Monday, in English, at noon UTC so no day slips across midnight.
    private func calendar(firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    @Test func theWeeksRunUpToToday() {
        let calendar = calendar()
        let columns = NoteRhythm.columns(weeks: 12, calendar: calendar, now: date(9, 27))
        #expect(columns.count == 12)
        #expect(columns[0][0] == calendar.startOfDay(for: date(7, 6)))
        #expect(columns[11][6] == calendar.startOfDay(for: date(9, 27)))
        // Midweek, the rest of the week is still to come.
        let midweek = NoteRhythm.columns(weeks: 2, calendar: calendar, now: date(9, 23))
        #expect(midweek[1].compactMap { $0 }.count == 3)
    }

    @Test func monthsAreNamedOverTheWeekTheyStartIn() {
        let calendar = calendar()
        let columns = NoteRhythm.columns(weeks: 12, calendar: calendar, now: date(9, 27))
        #expect(NoteRhythm.monthLabels(for: columns, calendar: calendar, locale: Locale(identifier: "en_US"))
            == ["jul", nil, nil, "aug", nil, nil, nil, nil, "sep", nil, nil, nil])
        #expect(NoteRhythm.monthLabels(for: columns, calendar: calendar, locale: Locale(identifier: "ru_RU"))[8] == "сент")
        // September starts two weeks in, too close for August to be named over the first week.
        let late = NoteRhythm.columns(weeks: 4, calendar: calendar, now: date(9, 13))
        #expect(NoteRhythm.monthLabels(for: late, calendar: calendar, locale: Locale(identifier: "en_US")) == [nil, nil, "sep", nil])
    }

    @Test func mondayWednesdayAndFridayAreNamedWhereverTheWeekStarts() {
        #expect((0..<7).map { NoteRhythm.weekdayLabel(row: $0, calendar: calendar()) } == ["mon", nil, "wed", nil, "fri", nil, nil])
        #expect((0..<7).map { NoteRhythm.weekdayLabel(row: $0, calendar: calendar(firstWeekday: 1)) } == [nil, "mon", nil, "wed", nil, "fri", nil])
    }
}
