import SwiftUI
import SwiftData

struct StartWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let templates: [WorkoutTemplate]
    var onStart: (WorkoutSession) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Button {
                            start(from: nil)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.white)
                                Text("Start Empty Workout")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .glassCard(cornerRadius: 18, padding: 16)
                        }
                        .buttonStyle(.plain)

                        if !templates.isEmpty {
                            Text("From Template")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CurveTheme.textSecondary)

                            VStack(spacing: 10) {
                                ForEach(templates) { template in
                                    Button {
                                        start(from: template)
                                    } label: {
                                        HStack {
                                            ZStack {
                                                Circle().fill(.white.opacity(0.16))
                                                Image(systemName: template.iconName)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                            .frame(width: 32, height: 32)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(template.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Text("\(template.sortedExercises.count) exercise\(template.sortedExercises.count == 1 ? "" : "s")")
                                                    .font(.caption)
                                                    .foregroundStyle(CurveTheme.textTertiary)
                                            }
                                            Spacer()
                                        }
                                        .glassCard(cornerRadius: 18, padding: 14)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
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
