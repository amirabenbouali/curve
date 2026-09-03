import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession

    @State private var restTimer = RestTimerModel()
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirmation = false
    @State private var showingDiscardConfirmation = false
    @State private var elapsedTimer: Timer?
    @State private var now = Date()

    var body: some View {
        VStack(spacing: 0) {
            if restTimer.isRunning {
                RestTimerBar(timer: restTimer)
                    .padding(.top, 8)
            }

            List {
                Section {
                    HStack {
                        TextField("Workout Name", text: $session.name)
                            .font(.headline)
                        Spacer()
                        Text(now.timeIntervalSince(session.startedAt).formattedDuration())
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(session.sortedExercises) { loggedExercise in
                    Section {
                        ExerciseLogSection(loggedExercise: loggedExercise, restTimer: restTimer)
                    } header: {
                        HStack {
                            Text(loggedExercise.displayName)
                            Spacer()
                            MuscleGroupChip(muscleGroup: loggedExercise.muscleGroup)
                        }
                    }
                }

                Section {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") { showingDiscardConfirmation = true }
                    .tint(.red)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") { showingFinishConfirmation = true }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                let logged = LoggedExercise(exercise: exercise, order: session.sortedExercises.count)
                logged.session = session
                context.insert(logged)
                let set = WorkoutSet(setIndex: 0)
                set.loggedExercise = logged
                context.insert(set)
            }
        }
        .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
            Button("Finish") { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will save your workout with \(session.completedSets.count) completed sets.")
        }
        .confirmationDialog("Discard this workout?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) { discardWorkout() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                now = Date()
            }
        }
        .onDisappear {
            elapsedTimer?.invalidate()
        }
        .interactiveDismissDisabled()
    }

    private func finishWorkout() {
        session.endedAt = Date()
        try? context.save()
        dismiss()
    }

    private func discardWorkout() {
        context.delete(session)
        try? context.save()
        dismiss()
    }
}

private struct ExerciseLogSection: View {
    @Environment(\.modelContext) private var context
    @Bindable var loggedExercise: LoggedExercise
    let restTimer: RestTimerModel

    var body: some View {
        ForEach(Array(loggedExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
            SetRowView(set: set, setNumber: index + 1) {
                if set.isCompleted {
                    restTimer.start(seconds: set.restSeconds)
                }
            }
        }
        .onDelete(perform: deleteSets)

        Button {
            addSet()
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.subheadline)
        }
    }

    private func addSet() {
        let lastSet = loggedExercise.sortedSets.last
        let set = WorkoutSet(
            setIndex: loggedExercise.sortedSets.count,
            reps: lastSet?.reps ?? 0,
            weight: lastSet?.weight ?? 0,
            restSeconds: lastSet?.restSeconds ?? 90
        )
        set.loggedExercise = loggedExercise
        context.insert(set)
    }

    private func deleteSets(at offsets: IndexSet) {
        let sorted = loggedExercise.sortedSets
        for index in offsets {
            context.delete(sorted[index])
        }
        for (index, set) in loggedExercise.sortedSets.enumerated() {
            set.setIndex = index
        }
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(name: "Push Day"))
    }
    .modelContainer(PreviewData.container)
}
