import Foundation
import UserNotifications

/// Schedules Curve's local notifications: a daily workout reminder (skipped
/// for days already trained), a once-per-week streak-risk warning if the
/// weekly goal isn't yet met, and a recurring weekly-summary nudge.
///
/// Local notifications can't carry content computed at delivery time without
/// a notification service extension, so the weekly summary uses fixed
/// copy ("your summary is ready") rather than embedding live numbers.
enum NotificationManager {
    private static let reminderPrefix = "workout-reminder-"
    private static let streakRiskID = "streak-risk"
    private static let weeklySummaryID = "weekly-summary"
    private static let reminderHour = 18

    static var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
    }

    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func refreshAll(
        sessions: [WorkoutSession],
        weeklyGoal: Int,
        remindersEnabled: Bool,
        streakRiskEnabled: Bool,
        weeklySummaryEnabled: Bool
    ) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)

            if remindersEnabled {
                scheduleWorkoutReminders(sessions: sessions, center: center)
            }
            if streakRiskEnabled {
                scheduleStreakRiskAlert(sessions: sessions, weeklyGoal: weeklyGoal, center: center)
            }
            if weeklySummaryEnabled {
                scheduleWeeklySummary(center: center)
            }
        }
    }

    /// Cancels today's reminder immediately after a workout is logged, so it
    /// doesn't fire later that evening even if a full refresh hasn't run yet.
    static func cancelTodaysReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(reminderPrefix)0"])
    }

    static func cancelStreakRiskAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [streakRiskID])
    }

    // MARK: - Scheduling

    private static func scheduleWorkoutReminders(sessions: [WorkoutSession], center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let completedToday = sessions.contains { !$0.isInProgress && calendar.isDateInToday($0.startedAt) }

        for dayOffset in 0..<7 {
            if dayOffset == 0 && completedToday { continue }
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: .now) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: date)
            comps.hour = reminderHour
            comps.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Time to train"
            content.body = "Log today's workout to keep your streak alive."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "\(reminderPrefix)\(dayOffset)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    private static func scheduleStreakRiskAlert(sessions: [WorkoutSession], weeklyGoal: Int, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let result = StreakEngine.calculate(sessions: sessions, weeklyGoal: weeklyGoal)
        guard result.thisWeekCount < weeklyGoal else { return }

        let weekStart = Date.now.startOfWeek(using: calendar)
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        var comps = calendar.dateComponents([.year, .month, .day], from: weekEnd)
        comps.hour = 17
        comps.minute = 0
        guard let fireDate = calendar.date(from: comps), fireDate > .now else { return }

        let remaining = weeklyGoal - result.thisWeekCount
        let content = UNMutableNotificationContent()
        content.title = "Your streak is at risk"
        content.body = "Log \(remaining) more workout\(remaining == 1 ? "" : "s") this week to keep your \(result.streakWeeks)-week streak."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: streakRiskID, content: content, trigger: trigger)
        center.add(request)
    }

    private static func scheduleWeeklySummary(center: UNUserNotificationCenter) {
        var comps = DateComponents()
        comps.weekday = 1 // Sunday
        comps.hour = 18
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Your weekly summary is ready"
        content.body = "See how many workouts, sets, and volume you logged this week."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: weeklySummaryID, content: content, trigger: trigger)
        center.add(request)
    }
}
