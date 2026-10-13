import Foundation

enum Dates {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.firstWeekday = 2
        calendar.timeZone = .current
        return calendar
    }

    static func key(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func parse(_ key: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key) ?? Date()
    }

    static func startOfDay(_ date: Date = Date()) -> Date {
        calendar.startOfDay(for: date)
    }

    static func prettyLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        let raw = formatter.string(from: date)
        guard let first = raw.first else { return raw }
        return first.uppercased() + raw.dropFirst()
    }

    static func prettyLong(key: String) -> String {
        prettyLong(parse(key))
    }

    static func prettyShort(key: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter.string(from: parse(key))
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        let raw = formatter.string(from: date)
        guard let first = raw.first else { return raw }
        return first.uppercased() + raw.dropFirst()
    }

    static func monday(of date: Date = Date()) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let mondayFirst = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -mondayFirst, to: startOfDay(date)) ?? startOfDay(date)
    }

    static func weekKeys(of date: Date = Date()) -> [String] {
        let start = monday(of: date)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map(key)
        }
    }

    static func monthGrid(_ date: Date) -> [String?] {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let start = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: start)
        else { return [] }

        let mondayFirst = (calendar.component(.weekday, from: start) + 5) % 7
        var cells: [String?] = Array(repeating: nil, count: mondayFirst)
        for day in range {
            var dayComps = comps
            dayComps.day = day
            if let value = calendar.date(from: dayComps) {
                cells.append(key(value))
            }
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    static func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func greeting(at date: Date = Date()) -> String {
        let hour = calendar.component(.hour, from: date)
        if hour < 10 { return String(localized: "greeting.morning") }
        if hour < 17 { return String(localized: "greeting.day") }
        return String(localized: "greeting.evening")
    }

    static func reminderComponents(_ hhmm: String) -> DateComponents {
        let parts = hhmm.split(separator: ":")
        let hour = Int(parts.first ?? "7") ?? 7
        let minute = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return comps
    }

    static func hhmm(from date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    static func date(fromHHMM hhmm: String) -> Date {
        let comps = reminderComponents(hhmm)
        return calendar.date(from: DateComponents(
            year: 2020,
            month: 1,
            day: 1,
            hour: comps.hour,
            minute: comps.minute
        )) ?? Date()
    }

    /// Monday-first: 0 = Monday … 6 = Sunday.
    static func weekdayIndex(_ date: Date = Date()) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    static func weekdayIndex(key: String) -> Int {
        weekdayIndex(parse(key))
    }
}
