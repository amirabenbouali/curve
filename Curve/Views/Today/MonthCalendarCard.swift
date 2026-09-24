import SwiftUI

/// Month grid showing which days had a logged workout, with a per-week status
/// column (goal met / freeze used / in progress) driven by `StreakEngine`.
struct MonthCalendarCard: View {
    let sessions: [WorkoutSession]
    let weeklyGoal: Int

    @State private var monthOffset = 0
    private let calendar = Calendar.current

    private enum WeekStatus { case goalMet, frozen, pending, none }

    private struct Day: Identifiable {
        var id: Date { date }
        let date: Date
        let isOutsideMonth: Bool
    }

    private struct Week: Identifiable {
        var id: Date { days[0].date }
        let days: [Day]
        let status: WeekStatus
    }

    private static let flameTint = Color(red: 1.0, green: 0.78, blue: 0.55)
    private static let freezeTint = Color(red: 0.78, green: 0.88, blue: 1.0)

    var body: some View {
        let weeks = buildWeeks()
        let logged = loggedDays
        let today = calendar.startOfDay(for: .now)

        VStack(spacing: 10) {
            header

            HStack(spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
                Color.clear.frame(width: 26, height: 1)
            }

            ForEach(weeks) { week in
                HStack(spacing: 4) {
                    ForEach(week.days) { day in
                        dayCell(day, isLogged: logged.contains(day.date), today: today)
                    }
                    statusIcon(week.status)
                        .frame(width: 26)
                }
            }

            legend
                .padding(.top, 6)
        }
        .glassCard(cornerRadius: 24, padding: 14)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button { monthOffset = effectiveOffset - 1 } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 24, height: 24)
            }
            .disabled(effectiveOffset <= minOffset)
            .opacity(effectiveOffset <= minOffset ? 0.25 : 1)
            .accessibilityLabel("Previous month")

            Text(displayedMonthStart.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            Button { monthOffset = effectiveOffset + 1 } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
            }
            .disabled(effectiveOffset >= 0)
            .opacity(effectiveOffset >= 0 ? 0.25 : 1)
            .accessibilityLabel("Next month")
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white.opacity(0.7))
        .buttonStyle(.plain)
    }

    private var legend: some View {
        HStack(spacing: 5) {
            Circle().fill(.white.opacity(0.35)).frame(width: 9, height: 9)
            Text("Logged")
            Image(systemName: "flame.fill")
                .foregroundStyle(Self.flameTint)
                .padding(.leading, 8)
            Text("Goal met")
            Image(systemName: "snowflake")
                .foregroundStyle(Self.freezeTint)
                .padding(.leading, 8)
            Text("Frozen")
            Spacer(minLength: 0)
        }
        .font(.system(size: 10))
        .foregroundStyle(.white.opacity(0.5))
    }

    private func dayCell(_ day: Day, isLogged: Bool, today: Date) -> some View {
        let isToday = day.date == today
        let isUpcoming = day.date > today
        let textColor: Color = isLogged ? .white : .white.opacity(isUpcoming ? 0.28 : 0.55)

        return Text("\(calendar.component(.day, from: day.date))")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textColor)
            .frame(width: 32, height: 32)
            .background(Circle().fill(isLogged ? .white.opacity(0.22) : .clear))
            .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.5).opacity(isToday ? 1 : 0))
            .frame(maxWidth: .infinity)
            .opacity(day.isOutsideMonth ? 0.5 : 1)
    }

    @ViewBuilder
    private func statusIcon(_ status: WeekStatus) -> some View {
        switch status {
        case .goalMet:
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundStyle(Self.flameTint)
                .accessibilityLabel("Weekly goal met")
        case .frozen:
            Image(systemName: "snowflake")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Self.freezeTint)
                .accessibilityLabel("Streak freeze used")
        case .pending:
            Text("·")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityHidden(true)
        case .none:
            Color.clear.frame(height: 1)
        }
    }

    // MARK: - Data

    private var completed: [WorkoutSession] { sessions.filter { !$0.isInProgress } }

    private var loggedDays: Set<Date> {
        Set(completed.map { calendar.startOfDay(for: $0.startedAt) })
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private var currentMonthStart: Date { startOfMonth(.now) }

    /// How far back the user can navigate: the month of their first completed workout.
    private var minOffset: Int {
        guard let earliest = completed.map(\.startedAt).min() else { return 0 }
        let months = calendar.dateComponents([.month], from: startOfMonth(earliest), to: currentMonthStart).month ?? 0
        return -max(months, 0)
    }

    private var effectiveOffset: Int { min(max(monthOffset, minOffset), 0) }

    private var displayedMonthStart: Date {
        calendar.date(byAdding: .month, value: effectiveOffset, to: currentMonthStart) ?? currentMonthStart
    }

    private func buildWeeks() -> [Week] {
        let monthStart = displayedMonthStart
        guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [] }

        let firstWeek = monthStart.startOfWeek(using: calendar)
        let currentWeek = Date.now.startOfWeek(using: calendar)
        let weeksBack = max(calendar.dateComponents([.weekOfYear], from: firstWeek, to: currentWeek).weekOfYear ?? 0, 0)
        let bars = StreakEngine.weeklyBreakdown(
            sessions: sessions,
            weeklyGoal: weeklyGoal,
            weeksToShow: weeksBack + 1,
            calendar: calendar
        )

        var weeks: [Week] = []
        var weekStart = firstWeek
        while weekStart < nextMonthStart {
            let days: [Day] = (0..<7).compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
                return Day(date: date, isOutsideMonth: date < monthStart || date >= nextMonthStart)
            }
            guard days.count == 7 else { break }

            let bar = bars.first { $0.start.map { calendar.isDate($0, inSameDayAs: weekStart) } ?? false }
            let status: WeekStatus
            if let bar {
                if bar.metGoal { status = .goalMet }
                else if bar.usedFreeze { status = .frozen }
                else if bar.isCurrent { status = .pending }
                else { status = .none }
            } else {
                status = .none
            }

            weeks.append(Week(days: days, status: status))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return weeks
    }
}

#Preview {
    ZStack {
        CurveBackground(palette: .plum)
        MonthCalendarCard(sessions: [], weeklyGoal: 4)
            .padding()
    }
}
