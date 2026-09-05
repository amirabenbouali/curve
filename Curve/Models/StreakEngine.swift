import Foundation

struct WeeklyStreakResult {
    var streakWeeks: Int
    var freezesAvailable: Int
    var thisWeekCount: Int
}

/// Computes a Duolingo-style weekly streak from workout history alone —
/// no persisted counters, so it's always consistent with the log.
///
/// Rule: a week "hits" when its completed-workout count meets `weeklyGoal`.
/// Every 4 consecutive hit weeks banks 1 freeze (cap 2). A missed week is
/// automatically covered by a banked freeze if one is available, which
/// keeps the streak alive but doesn't itself earn toward the next freeze.
enum StreakEngine {
    static func calculate(
        sessions: [WorkoutSession],
        weeklyGoal: Int,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> WeeklyStreakResult {
        guard weeklyGoal > 0 else {
            return WeeklyStreakResult(streakWeeks: 0, freezesAvailable: 0, thisWeekCount: 0)
        }

        let completed = sessions.filter { !$0.isInProgress }
        var countsByWeek: [Date: Int] = [:]
        for session in completed {
            let week = session.startedAt.startOfWeek(using: calendar)
            countsByWeek[week, default: 0] += 1
        }

        let currentWeekStart = now.startOfWeek(using: calendar)
        let thisWeekCount = countsByWeek[currentWeekStart] ?? 0
        let includesThisWeek = thisWeekCount >= weeklyGoal

        var freezeBank = 0
        var consecutiveHits = 0
        var streak = 0
        var week = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart

        var weeksWalked = 0
        let maxWeeksToWalk = 260 // ~5 years safety cap
        var stillCounting = true

        while stillCounting && weeksWalked < maxWeeksToWalk {
            let count = countsByWeek[week] ?? 0
            if count >= weeklyGoal {
                streak += 1
                consecutiveHits += 1
                if consecutiveHits % 4 == 0 {
                    freezeBank = min(freezeBank + 1, 2)
                }
            } else if freezeBank > 0 {
                freezeBank -= 1
                streak += 1
                consecutiveHits = 0
            } else {
                stillCounting = false
            }

            if stillCounting {
                week = calendar.date(byAdding: .weekOfYear, value: -1, to: week) ?? week
                weeksWalked += 1
            }
        }

        return WeeklyStreakResult(
            streakWeeks: streak + (includesThisWeek ? 1 : 0),
            freezesAvailable: freezeBank,
            thisWeekCount: thisWeekCount
        )
    }

    /// Per-week workout counts for the last `weeksToShow` weeks (oldest first,
    /// ending with the current in-progress week), walking the freeze bank
    /// forward chronologically so freeze marks land on the week they actually
    /// covered — independent of whether today's streak is still alive.
    static func weeklyBreakdown(
        sessions: [WorkoutSession],
        weeklyGoal: Int,
        weeksToShow: Int = 8,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [PeriodBar] {
        guard weeklyGoal > 0 else { return [] }

        let completed = sessions.filter { !$0.isInProgress }
        var countsByWeek: [Date: Int] = [:]
        for session in completed {
            let week = session.startedAt.startOfWeek(using: calendar)
            countsByWeek[week, default: 0] += 1
        }

        let currentWeekStart = now.startOfWeek(using: calendar)
        let earliestWeek = countsByWeek.keys.min() ?? currentWeekStart
        let startWeek = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: currentWeekStart) ?? currentWeekStart
        var week = min(earliestWeek, startWeek)

        var freezeBank = 0
        var consecutiveHits = 0
        var results: [PeriodBar] = []
        var weeksWalked = 0
        let maxWeeks = 520

        while week <= currentWeekStart && weeksWalked < maxWeeks {
            let count = countsByWeek[week] ?? 0
            let isCurrent = week == currentWeekStart
            var metGoal = false
            var usedFreeze = false

            if isCurrent {
                metGoal = count >= weeklyGoal
            } else if count >= weeklyGoal {
                metGoal = true
                consecutiveHits += 1
                if consecutiveHits % 4 == 0 { freezeBank = min(freezeBank + 1, 2) }
            } else if freezeBank > 0 {
                freezeBank -= 1
                usedFreeze = true
                consecutiveHits = 0
            } else {
                consecutiveHits = 0
            }

            let weeksAgo = calendar.dateComponents([.weekOfYear], from: week, to: currentWeekStart).weekOfYear ?? 0
            results.append(PeriodBar(
                label: isCurrent ? "Now" : "\(weeksAgo)wk",
                count: count,
                isCurrent: isCurrent,
                metGoal: metGoal,
                usedFreeze: usedFreeze
            ))

            week = calendar.date(byAdding: .weekOfYear, value: 1, to: week) ?? currentWeekStart
            weeksWalked += 1
        }

        return Array(results.suffix(weeksToShow))
    }

    /// Bucketed workout counts by month or year, scaled against `weeklyGoal`.
    /// No freeze tracking — freezes are a weekly-streak-only mechanic.
    static func periodBreakdown(
        sessions: [WorkoutSession],
        weeklyGoal: Int,
        component: Calendar.Component,
        periodsToShow: Int,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [PeriodBar] {
        guard weeklyGoal > 0 else { return [] }
        let completed = sessions.filter { !$0.isInProgress }

        func periodStart(for date: Date) -> Date {
            switch component {
            case .month:
                let comps = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: comps) ?? date
            case .year:
                let comps = calendar.dateComponents([.year], from: date)
                return calendar.date(from: comps) ?? date
            default:
                return date.startOfWeek(using: calendar)
            }
        }

        var countsByPeriod: [Date: Int] = [:]
        for session in completed {
            countsByPeriod[periodStart(for: session.startedAt), default: 0] += 1
        }

        let currentPeriodStart = periodStart(for: now)
        let goal: Int = component == .year ? weeklyGoal * 52 : weeklyGoal * 4

        var period = calendar.date(byAdding: component, value: -(periodsToShow - 1), to: currentPeriodStart) ?? currentPeriodStart
        var results: [PeriodBar] = []
        var walked = 0

        while period <= currentPeriodStart && walked < periodsToShow {
            let count = countsByPeriod[period] ?? 0
            let isCurrent = period == currentPeriodStart
            let label: String
            switch component {
            case .month:
                label = isCurrent ? "Now" : period.formatted(.dateTime.month(.abbreviated))
            case .year:
                label = isCurrent ? "Now" : period.formatted(.dateTime.year())
            default:
                label = isCurrent ? "Now" : ""
            }
            results.append(PeriodBar(label: label, count: count, isCurrent: isCurrent, metGoal: count >= goal, usedFreeze: false))
            period = calendar.date(byAdding: component, value: 1, to: period) ?? currentPeriodStart
            walked += 1
        }

        return results
    }
}

struct PeriodBar: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let isCurrent: Bool
    let metGoal: Bool
    let usedFreeze: Bool
}
