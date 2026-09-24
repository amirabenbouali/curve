import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct CurveApp: App {
    let container: ModelContainer

    @AppStorage("weeklyGoal") private var weeklyGoal = 4
    @AppStorage("workoutRemindersEnabled") private var remindersEnabled = true
    @AppStorage("streakRiskAlertsEnabled") private var streakRiskEnabled = true
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Only configure Firebase once GoogleService-Info.plist is actually in the
        // bundle — FirebaseApp.configure() fatal-errors without it, and everything
        // in AuthManager/SyncManager is written to no-op gracefully until then.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }

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
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onComplete: { hasCompletedOnboarding = true })
                }
            }
            .task {
                ExerciseSeedData.seedIfNeeded(context: container.mainContext)
                if remindersEnabled || streakRiskEnabled || weeklySummaryEnabled {
                    let descriptor = FetchDescriptor<WorkoutSession>()
                    let sessions = (try? container.mainContext.fetch(descriptor)) ?? []
                    NotificationManager.refreshAll(
                        sessions: sessions,
                        weeklyGoal: weeklyGoal,
                        remindersEnabled: remindersEnabled,
                        streakRiskEnabled: streakRiskEnabled,
                        weeklySummaryEnabled: weeklySummaryEnabled
                    )
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(container)
    }
}
