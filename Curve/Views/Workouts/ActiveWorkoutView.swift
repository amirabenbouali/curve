import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession

    @State private var restTimer = RestTimerModel()
    @State private var selectedExerciseIndex: Int = 0
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirmation = false
    @State private var elapsedTimer: Timer?
    @State private var now = Date()

    private var exercises: [LoggedExercise] { session.sortedExercises }

    private var selectedExercise: LoggedExercise? {
        exercises.indices.contains(selectedExerciseIndex) ? exercises[selectedExerciseIndex] : nil
    }

    private func hasIncomplete(_ exercise: LoggedExercise) -> Bool {
        exercise.sortedSets.contains { !$0.isCompleted }
    }

    private func firstIncompleteSetIndex(in exercise: LoggedExercise) -> Int {
        let sets = exercise.sortedSets
        return sets.firstIndex(where: { !$0.isCompleted }) ?? max(sets.count - 1, 0)
    }

    private var currentSet: WorkoutSet? {
        guard let selectedExercise else { return nil }
        let sets = selectedExercise.sortedSets
        let idx = firstIncompleteSetIndex(in: selectedExercise)
        return sets.indices.contains(idx) ? sets[idx] : nil
    }

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if exercises.isEmpty {
                        emptyState
                    } else {
                        progressTrack

                        if let selectedExercise, let currentSet {
                            exerciseCard(selectedExercise, currentSet: currentSet)
                        }

                        if restTimer.isRunning {
                            restCard
                        }

                        Text("Workout order")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        VStack(spacing: 8) {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                                orderRow(exercise, index: index)
                            }
                            addExerciseRow
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                finishBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                let logged = LoggedExercise(exercise: exercise, order: exercises.count)
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
            Text("This will save your workout with \(session.completedSets.count) completed set\(session.completedSets.count == 1 ? "" : "s").")
        }
        .onAppear {
            selectedExerciseIndex = exercises.firstIndex(where: hasIncomplete) ?? max(exercises.count - 1, 0)
            elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in now = Date() }
        }
        .onDisappear { elapsedTimer?.invalidate() }
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .glassCard(cornerRadius: 18, padding: 0)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text(session.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(exercises.isEmpty ? "No exercises yet" : "Exercise \(min(selectedExerciseIndex + 1, exercises.count)) of \(exercises.count)")
                    .font(.curveEyebrow(12))
                    .foregroundStyle(CurveTheme.textSecondary)
            }

            Spacer()

            Text(formattedElapsed(now.timeIntervalSince(session.startedAt)))
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 20, padding: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No exercises yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text("Add your first exercise to start logging.")
                .font(.system(size: 12))
                .foregroundStyle(CurveTheme.textSecondary)
            Button("Add Exercise") { showingExercisePicker = true }
                .buttonStyle(.curveChrome)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Progress track

    private var progressTrack: some View {
        HStack(spacing: 6) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                Capsule()
                    .fill(segmentFill(for: exercise, index: index))
                    .frame(height: 4)
            }
        }
    }

    private func segmentFill(for exercise: LoggedExercise, index: Int) -> AnyShapeStyle {
        if !hasIncomplete(exercise) { return AnyShapeStyle(CurveTheme.progressFill) }
        if index == selectedExerciseIndex { return AnyShapeStyle(.white.opacity(0.65)) }
        return AnyShapeStyle(.white.opacity(0.18))
    }

    // MARK: - Exercise card

    private func exerciseCard(_ exercise: LoggedExercise, currentSet: WorkoutSet) -> some View {
        let sets = exercise.sortedSets
        let currentIndex = firstIncompleteSetIndex(in: exercise)

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NOW LOGGING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(CurveTheme.textSecondary)
                Text(exercise.displayName)
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(.white)
                Text(exercise.muscleGroup.displayName)
                    .font(.curveEyebrow(13))
                    .foregroundStyle(CurveTheme.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    Circle()
                        .fill(set.isCompleted ? Color.white : Color.white.opacity(0.22))
                        .overlay(
                            Circle().strokeBorder(.white, lineWidth: index == currentIndex && !set.isCompleted ? 1.5 : 0)
                        )
                        .frame(width: 9, height: 9)
                }
                Text("Set \(min(currentIndex + 1, sets.count)) of \(sets.count)")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(CurveTheme.textSecondary)
                Spacer()
                Button {
                    addSetToCurrentExercise(exercise)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                IntStepperField(label: "REPS", value: Binding(get: { currentSet.reps }, set: { currentSet.reps = max(0, $0) }), unit: "reps", step: 1)
                DoubleStepperField(label: "WEIGHT", value: Binding(get: { currentSet.weight }, set: { currentSet.weight = max(0, $0) }), unit: "lb", step: 2.5)
            }

            Button("Log set") { logCurrentSet(currentSet, exercise: exercise) }
                .buttonStyle(.curveChrome)
        }
        .padding(22)
        .glassCard(padding: 0)
    }

    // MARK: - Rest card

    private var restCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Resting")
                    .font(.curveEyebrow(14))
                    .foregroundStyle(CurveTheme.textSecondary)
                Text(formattedRest(restTimer.remainingSeconds))
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button("Skip rest") { restTimer.stop() }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1))
        }
        .glassCard(cornerRadius: 18, padding: 18)
    }

    // MARK: - Workout order list

    private func orderRow(_ exercise: LoggedExercise, index: Int) -> some View {
        let isCurrent = index == selectedExerciseIndex
        let isDone = !hasIncomplete(exercise)
        let completedCount = exercise.sortedSets.filter { $0.isCompleted }.count

        return Button {
            selectedExerciseIndex = index
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(statusFill(isDone: isDone, isCurrent: isCurrent))
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color(red: 0.078, green: 0.129, blue: 0.114))
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(.white.opacity(isCurrent ? 0.7 : (isDone ? 0 : 0.22)), lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.displayName)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(isCurrent ? .white : .white.opacity(0.55))
                    Text(orderSubtitle(exercise, isCurrent: isCurrent, isDone: isDone, completedCount: completedCount))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            .glassCard(cornerRadius: 16, padding: 12)
        }
        .buttonStyle(.plain)
    }

    private func statusFill(isDone: Bool, isCurrent: Bool) -> AnyShapeStyle {
        if isDone { return AnyShapeStyle(CurveTheme.chrome) }
        if isCurrent { return AnyShapeStyle(.white.opacity(0.16)) }
        return AnyShapeStyle(.white.opacity(0.08))
    }

    private func orderSubtitle(_ exercise: LoggedExercise, isCurrent: Bool, isDone: Bool, completedCount: Int) -> String {
        let total = exercise.sortedSets.count
        if isDone { return "\(total) sets · completed" }
        if isCurrent { return "Set \(completedCount + 1) of \(total) in progress" }
        return "\(total) sets"
    }

    private var addExerciseRow: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
                Spacer()
            }
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(.white.opacity(0.85))
            .glassCard(cornerRadius: 16, padding: 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Finish bar

    private var finishBar: some View {
        Button("Finish workout") { showingFinishConfirmation = true }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .glassCard(cornerRadius: 18, padding: 0)
    }

    // MARK: - Actions

    private func logCurrentSet(_ set: WorkoutSet, exercise: LoggedExercise) {
        set.isCompleted = true
        try? context.save()

        let stillHasIncomplete = hasIncomplete(exercise)
        let workoutFullyComplete = !stillHasIncomplete && !exercises.contains(where: hasIncomplete)

        if !workoutFullyComplete {
            restTimer.start(seconds: set.restSeconds)
        }

        if !stillHasIncomplete {
            if let nextIndex = exercises.firstIndex(where: hasIncomplete) {
                selectedExerciseIndex = nextIndex
            } else if selectedExerciseIndex < exercises.count - 1 {
                selectedExerciseIndex += 1
            }
        }
    }

    private func addSetToCurrentExercise(_ exercise: LoggedExercise) {
        let sets = exercise.sortedSets
        let last = sets.last
        let newSet = WorkoutSet(setIndex: sets.count, reps: last?.reps ?? 0, weight: last?.weight ?? 0, restSeconds: last?.restSeconds ?? 90)
        newSet.loggedExercise = exercise
        context.insert(newSet)
    }

    private func finishWorkout() {
        session.endedAt = Date()
        try? context.save()
        dismiss()
    }

    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formattedRest(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Stepper fields

private struct IntStepperField: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let step: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 10) {
                stepperButton("minus") { value = max(0, value - step) }
                VStack(spacing: 0) {
                    Text("\(value)")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(minWidth: 44)
                stepperButton("plus") { value += step }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }

    private func stepperButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }
}

private struct DoubleStepperField: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let step: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 10) {
                stepperButton("minus") { value = max(0, value - step) }
                VStack(spacing: 0) {
                    Text(value.formattedWeight())
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(minWidth: 44)
                stepperButton("plus") { value += step }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }

    private func stepperButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(name: "Push Day"))
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
