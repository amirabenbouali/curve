import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID = UUID()
    var exercise: Exercise?
    var exerciseNameSnapshot: String = ""
    var muscleGroupRaw: String = MuscleGroup.fullBody.rawValue
    var order: Int = 0
    var targetSets: Int = 3
    var targetReps: Int = 10
    var targetWeight: Double = 0
    var restSeconds: Int = 90

    var template: WorkoutTemplate?

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    init(exercise: Exercise, order: Int, targetSets: Int = 3, targetReps: Int = 10, targetWeight: Double = 0, restSeconds: Int = 90) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseNameSnapshot = exercise.name
        self.muscleGroupRaw = exercise.muscleGroup.rawValue
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
    }

    var displayName: String {
        exercise?.name ?? exerciseNameSnapshot
    }
}
