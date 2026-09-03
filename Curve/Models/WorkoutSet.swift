import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var setIndex: Int = 0
    var reps: Int = 0
    var weight: Double = 0
    var restSeconds: Int = 90
    var isWarmup: Bool = false
    var isCompleted: Bool = false

    var loggedExercise: LoggedExercise?

    init(setIndex: Int, reps: Int = 0, weight: Double = 0, restSeconds: Int = 90, isWarmup: Bool = false) {
        self.id = UUID()
        self.setIndex = setIndex
        self.reps = reps
        self.weight = weight
        self.restSeconds = restSeconds
        self.isWarmup = isWarmup
        self.isCompleted = false
    }

    /// Epley formula estimate.
    var estimatedOneRepMax: Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}
