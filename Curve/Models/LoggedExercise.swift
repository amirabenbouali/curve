import Foundation
import SwiftData

@Model
final class LoggedExercise {
    var id: UUID = UUID()
    var exercise: Exercise?
    var exerciseNameSnapshot: String = ""
    var muscleGroupRaw: String = MuscleGroup.fullBody.rawValue
    var order: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.loggedExercise)
    var sets: [WorkoutSet]? = []

    var session: WorkoutSession?

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    init(exercise: Exercise, order: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseNameSnapshot = exercise.name
        self.muscleGroupRaw = exercise.muscleGroup.rawValue
        self.order = order
    }

    var displayName: String {
        exercise?.name ?? exerciseNameSnapshot
    }

    var sortedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.setIndex < $1.setIndex }
    }

    var topSetWeight: Double {
        sortedSets.filter { $0.isCompleted && !$0.isWarmup }.map { $0.weight }.max() ?? 0
    }

    var totalVolume: Double {
        sortedSets.filter { $0.isCompleted }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}
