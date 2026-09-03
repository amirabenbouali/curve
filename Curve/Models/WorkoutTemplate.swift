import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "figure.strengthtraining.traditional"
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]? = []

    init(name: String, iconName: String = "figure.strengthtraining.traditional") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.createdAt = Date()
    }

    var sortedExercises: [TemplateExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    var muscleGroups: [MuscleGroup] {
        let groups = sortedExercises.map { $0.muscleGroup }
        var seen = Set<MuscleGroup>()
        return groups.filter { seen.insert($0).inserted }
    }
}
