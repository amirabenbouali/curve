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
        ZStack {
            CurveBackground()

            VStack(spacing: 0) {
                if restTimer.isRunning {
                    RestTimerBar(timer: restTimer)
                        .padding(.top, 8)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            TextField("Workout Name", text: $session.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(now.timeIntervalSince(session.startedAt).formattedDuration())
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(CurveTheme.textSecondary)
                        }
                        .glassCard(cornerRadius: 18, padding: 14)

                        ForEach(session.sortedExercises) { loggedExercise in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(loggedExercise.displayName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    MuscleGroupChip(muscleGroup: loggedExercise.muscleGroup)
                                }
                                ExerciseLogSection(loggedExercise: loggedExercise, restTimer: restTimer)
                            }
                            .glassCard(cornerRadius: 18, padding: 14)
                        }

                        Button {
                            showingExercisePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                                Spacer()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .glassCard(cornerRadius: 18, padding: 14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
        .preferredColorScheme(.dark)
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
        VStack(spacing: 6) {
            ForEach(Array(loggedExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                SetRowView(set: set, setNumber: index + 1) {
                    if set.isCompleted {
                        restTimer.start(seconds: set.restSeconds)
                    }
                }
                if index < loggedExercise.sortedSets.count - 1 {
                    Divider().overlay(CurveTheme.hairline)
                }
            }
        }

        Button {
            addSet()
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
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
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(name: "Push Day"))
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
