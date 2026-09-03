import SwiftUI
import SwiftData

@main
struct CurveApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            WorkoutSession.self,
            LoggedExercise.self,
            WorkoutSet.self,
            BodyStatEntry.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    ExerciseSeedData.seedIfNeeded(context: container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
