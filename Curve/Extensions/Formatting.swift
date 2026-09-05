import Foundation

enum WeightUnit: String, CaseIterable {
    case lb, kg

    var label: String { rawValue }
}

extension Double {
    func formattedWeight() -> String {
        if self == self.rounded() {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }
}

extension TimeInterval {
    func formattedDuration() -> String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    func formattedRest() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }
}

extension Date {
    func formattedShort() -> String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    func formattedFull() -> String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }

    func startOfWeek(using calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func relativeDescription() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
