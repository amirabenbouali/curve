import Foundation

struct PersonalRecord: Identifiable {
    var id: String { exerciseName }
    let exerciseName: String
    let weight: Double
    let reps: Int
    let date: Date
}

/// Finds each exercise's current standing PR (heaviest completed, non-warmup
/// set ever logged) along with the date it was actually set — i.e. the
/// session where that weight first became the max, not just the most recent
/// time the exercise was performed at that weight.
enum PersonalRecordEngine {
    static func currentRecords(sessions: [WorkoutSession]) -> [PersonalRecord] {
        let completed = sessions.filter { !$0.isInProgress }.sorted { $0.startedAt < $1.startedAt }

        var runningMax: [String: Double] = [:]
        var records: [String: PersonalRecord] = [:]

        for session in completed {
            for exercise in session.sortedExercises {
                let name = exercise.displayName
                for set in exercise.sortedSets where set.isCompleted && !set.isWarmup {
                    let currentMax = runningMax[name] ?? 0
                    if set.weight > currentMax {
                        runningMax[name] = set.weight
                        records[name] = PersonalRecord(exerciseName: name, weight: set.weight, reps: set.reps, date: session.startedAt)
                    }
                }
            }
        }

        return records.values.sorted { $0.date > $1.date }
    }

    /// IDs of sessions where at least one exercise's weight surpassed its
    /// previous all-time max at that point in the log — i.e. the session
    /// actually set a new PR, for badging in the Log list.
    static func sessionsWithPR(sessions: [WorkoutSession]) -> Set<UUID> {
        let completed = sessions.filter { !$0.isInProgress }.sorted { $0.startedAt < $1.startedAt }

        var runningMax: [String: Double] = [:]
        var sessionIDs: Set<UUID> = []

        for session in completed {
            for exercise in session.sortedExercises {
                let name = exercise.displayName
                for set in exercise.sortedSets where set.isCompleted && !set.isWarmup {
                    let currentMax = runningMax[name] ?? 0
                    if set.weight > currentMax {
                        runningMax[name] = set.weight
                        sessionIDs.insert(session.id)
                    }
                }
            }
        }

        return sessionIDs
    }
}
