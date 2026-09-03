import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            WorkoutSession.self,
            LoggedExercise.self,
            WorkoutSet.self,
            BodyStatEntry.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        ExerciseSeedData.seedIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = (try? context.fetch(descriptor)) ?? []

        guard let bench = exercises.first(where: { $0.name == "Barbell Bench Press" }),
              let squat = exercises.first(where: { $0.name == "Back Squat" }) else {
            return container
        }

        let template = WorkoutTemplate(name: "Push Day")
        context.insert(template)
        let te1 = TemplateExercise(exercise: bench, order: 0)
        te1.template = template
        context.insert(te1)

        let session = WorkoutSession(name: "Push Day", startedAt: .now.addingTimeInterval(-3600))
        session.endedAt = .now
        context.insert(session)
        let logged = LoggedExercise(exercise: squat, order: 0)
        logged.session = session
        context.insert(logged)
        let set1 = WorkoutSet(setIndex: 0, reps: 8, weight: 135)
        set1.isCompleted = true
        set1.loggedExercise = logged
        context.insert(set1)

        context.insert(BodyStatEntry(date: .now, weight: 180, bodyFatPercentage: 15))

        try? context.save()
        return container
    }()
}
