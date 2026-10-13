import Foundation

enum Dates {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "da_DK")
        calendar.firstWeekday = 2
        calendar.timeZone = .current
        return calendar
    }

    static let danish = Locale(identifier: "da_DK")

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
        formatter.locale = danish
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE d. MMMM"
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    static func prettyLong(key: String) -> String {
        prettyLong(parse(key))
    }

    static func prettyShort(key: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = danish
        formatter.calendar = calendar
        formatter.dateFormat = "d. MMM"
        return formatter.string(from: parse(key))
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = danish
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM yyyy"
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    static func monday(of date: Date = Date()) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        // Sunday = 1 … Saturday = 7. Monday-first offset:
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
            if let d = calendar.date(from: dayComps) {
                cells.append(key(d))
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
        if hour < 10 { return "God morgen" }
        if hour < 17 { return "God dag" }
        return "God aften"
    }

    static func reminderComponents(_ hhmm: String) -> DateComponents {
        let parts = hhmm.split(separator: ":")
        let hour = Int(parts.first ?? "6") ?? 6
        let minute = parts.count > 1 ? Int(parts[1]) ?? 15 : 15
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return comps
    }
}
