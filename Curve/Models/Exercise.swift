import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupRaw: String = MuscleGroup.fullBody.rawValue
    var isCustom: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateExercises: [TemplateExercise]? = []

    @Relationship(deleteRule: .nullify, inverse: \LoggedExercise.exercise)
    var loggedExercises: [LoggedExercise]? = []

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    init(name: String, muscleGroup: MuscleGroup, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.isCustom = isCustom
        self.createdAt = Date()
    }
}
