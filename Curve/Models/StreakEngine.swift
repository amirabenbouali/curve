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
}
