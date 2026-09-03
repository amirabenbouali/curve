import SwiftUI
import SwiftData

struct StartWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let templates: [WorkoutTemplate]
    var onStart: (WorkoutSession) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        start(from: nil)
                    } label: {
                        Label("Start Empty Workout", systemImage: "plus.circle")
                    }
                }
                if !templates.isEmpty {
                    Section("From Template") {
                        ForEach(templates) { template in
                            Button {
                                start(from: template)
                            } label: {
                                HStack {
                                    Image(systemName: template.iconName)
                                        .foregroundStyle(Color.accentColor)
                                    VStack(alignment: .leading) {
                                        Text(template.name)
                                            .foregroundStyle(.primary)
                                        Text("\(template.sortedExercises.count) exercises")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func start(from template: WorkoutTemplate?) {
        let session = WorkoutSession(name: template?.name ?? "Workout", templateNameSnapshot: template?.name)
        context.insert(session)

        if let template {
            for templateExercise in template.sortedExercises {
                guard let exercise = templateExercise.exercise else { continue }
                let logged = LoggedExercise(exercise: exercise, order: templateExercise.order)
                logged.session = session
                context.insert(logged)
                for index in 0..<templateExercise.targetSets {
                    let set = WorkoutSet(setIndex: index, reps: templateExercise.targetReps, weight: templateExercise.targetWeight, restSeconds: templateExercise.restSeconds)
                    set.loggedExercise = logged
                    context.insert(set)
                }
            }
        }

        try? context.save()
        dismiss()
        onStart(session)
    }
}
