import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var template: WorkoutTemplate
    var isNew: Bool = false

    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.lb.rawValue
    @State private var showingExercisePicker = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    var body: some View {
        ZStack {
            CurveBackground(palette: .plum)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameField
                    iconPicker

                    Text("Exercises")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 4)

                    if template.sortedExercises.isEmpty {
                        Text("No exercises added yet.")
                            .font(.system(size: 13))
                            .foregroundStyle(CurveTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(cornerRadius: 20, padding: 16)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(template.sortedExercises.enumerated()), id: \.element.id) { index, templateExercise in
                                TemplateExerciseRow(
                                    templateExercise: templateExercise,
                                    weightUnit: weightUnit,
                                    isFirst: index == 0,
                                    isLast: index == template.sortedExercises.count - 1,
                                    onMoveUp: { move(templateExercise, by: -1) },
                                    onMoveDown: { move(templateExercise, by: 1) },
                                    onDelete: { delete(templateExercise) }
                                )
                            }
                        }
                    }

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
                        .glassCard(cornerRadius: 18, padding: 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .environment(\.curvePalette, .plum)
        .navigationTitle(isNew ? "New Template" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(template)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        SyncManager.pushTemplate(template)
                        dismiss()
                    }
                    .disabled(template.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                let templateExercise = TemplateExercise(exercise: exercise, order: template.sortedExercises.count, restSeconds: defaultRestSeconds)
                templateExercise.template = template
                context.insert(templateExercise)
            }
        }
        .onDisappear {
            // isNew templates push explicitly via Save/Cancel above; this
            // captures live edits (name, exercises, sets/reps) made while
            // editing an existing template, on the way back out.
            if !isNew {
                SyncManager.pushTemplate(template)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAME")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(CurveTheme.textSecondary)
            TextField("Template name", text: $template.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 20, padding: 0)
    }

    private var iconPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TemplateIcon.all, id: \.self) { icon in
                    let isSelected = template.iconName == icon
                    Button {
                        template.iconName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(isSelected ? 0.30 : 0.10)))
                            .overlay(Circle().strokeBorder(.white.opacity(isSelected ? 0.85 : 0.25), lineWidth: isSelected ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func move(_ templateExercise: TemplateExercise, by offset: Int) {
        var sorted = template.sortedExercises
        guard let index = sorted.firstIndex(where: { $0.id == templateExercise.id }) else { return }
        let newIndex = index + offset
        guard sorted.indices.contains(newIndex) else { return }
        sorted.swapAt(index, newIndex)
        for (order, exercise) in sorted.enumerated() {
            exercise.order = order
        }
    }

    private func delete(_ templateExercise: TemplateExercise) {
        context.delete(templateExercise)
        for (order, exercise) in template.sortedExercises.enumerated() {
            exercise.order = order
        }
    }
}

private enum TemplateIcon {
    static let all = [
        "figure.strengthtraining.traditional", "figure.strengthtraining.functional",
        "figure.arms.open", "figure.core.training", "figure.rower",
        "figure.run", "figure.squat", "dumbbell.fill", "figure.mixed.cardio",
        "figure.boxing",
    ]
}

private struct TemplateExerciseRow: View {
    @Bindable var templateExercise: TemplateExercise
    let weightUnit: WeightUnit
    let isFirst: Bool
    let isLast: Bool
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(templateExercise.displayName)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                MuscleGroupChip(muscleGroup: templateExercise.muscleGroup)
            }

            HStack(spacing: 10) {
                IntStepperField(label: "SETS", value: $templateExercise.targetSets, step: 1, minValue: 1)
                IntStepperField(label: "REPS", value: $templateExercise.targetReps, step: 1, minValue: 1)
            }

            DoubleStepperField(
                label: "WEIGHT",
                value: Binding(
                    get: { weightUnit.fromCanonicalLb(templateExercise.targetWeight) },
                    set: { templateExercise.targetWeight = max(0, weightUnit.toCanonicalLb($0)) }
                ),
                unit: weightUnit.label,
                step: weightUnit.stepSize
            )

            HStack(spacing: 16) {
                reorderButton("chevron.up", action: onMoveUp, disabled: isFirst)
                reorderButton("chevron.down", action: onMoveDown, disabled: isLast)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.941, green: 0.718, blue: 0.659))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20, padding: 0)
    }

    private func reorderButton(_ systemName: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(disabled ? 0.25 : 0.75))
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

#Preview {
    NavigationStack {
        TemplateEditorView(template: WorkoutTemplate(name: "Leg Day"))
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
