import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg

    var id: String { rawValue }
    var label: String { rawValue }

    /// Reasonable plate/dumbbell increment for stepper controls.
    var stepSize: Double { self == .kg ? 1.25 : 2.5 }

    private static let kgPerLb = 0.45359237

    /// Weight is always stored canonically in pounds; this converts for display.
    func fromCanonicalLb(_ lbValue: Double) -> Double {
        self == .kg ? lbValue * Self.kgPerLb : lbValue
    }

    /// Converts a value entered in this unit back to canonical pounds for storage.
    func toCanonicalLb(_ value: Double) -> Double {
        self == .kg ? value / Self.kgPerLb : value
    }
}

extension Double {
    func formattedWeight() -> String {
        if self == self.rounded() {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }

    /// Formats a canonical-pounds value in the given display unit, with unit suffix.
    func displayWeight(unit: WeightUnit) -> String {
        "\(unit.fromCanonicalLb(self).formattedWeight()) \(unit.label)"
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
