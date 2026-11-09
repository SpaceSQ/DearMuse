import Foundation

public enum CalendarKeys {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static func todayKey(now: Date = Date()) -> String {
        dayFormatter.string(from: now)
    }

    public static func daysAgoKey(_ days: Int, now: Date = Date()) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return dayFormatter.string(from: date)
    }

    public static func isoWeekKey(now: Date = Date()) -> String {
        let cal = Calendar(identifier: .iso8601)
        let year = cal.component(.yearForWeekOfYear, from: now)
        let week = cal.component(.weekOfYear, from: now)
        return String(format: "%d-W%02d", year, week)
    }

    public static func isSundayEveningWindow(now: Date = Date()) -> Bool {
        let cal = Calendar.current
        return cal.component(.weekday, from: now) == 1
    }
}
