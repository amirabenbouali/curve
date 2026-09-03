import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var name: String = "Workout"
    var templateNameSnapshot: String?
    var startedAt: Date = Date()
    var endedAt: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]? = []

    init(name: String, templateNameSnapshot: String? = nil, startedAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.templateNameSnapshot = templateNameSnapshot
        self.startedAt = startedAt
    }

    var isInProgress: Bool { endedAt == nil }

    var duration: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }

    var sortedExercises: [LoggedExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    var completedSets: [WorkoutSet] {
        sortedExercises.flatMap { $0.sortedSets }.filter { $0.isCompleted }
    }

    var totalSets: Int { completedSets.count }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var muscleGroups: [MuscleGroup] {
        let groups = sortedExercises.map { $0.muscleGroup }
        var seen = Set<MuscleGroup>()
        return groups.filter { seen.insert($0).inserted }
    }
}
