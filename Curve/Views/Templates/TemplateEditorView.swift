import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var template: WorkoutTemplate
    var isNew: Bool = false

    @State private var showingExercisePicker = false

    var body: some View {
        ZStack {
            CurveBackground()
            Form {
                Section {
                    TextField("Template Name", text: $template.name)
                    IconPicker(selection: $template.iconName)
                }
                .listRowBackground(Color.white.opacity(0.08))

                Section("Exercises") {
                    if template.sortedExercises.isEmpty {
                        Text("No exercises added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(template.sortedExercises) { templateExercise in
                            TemplateExerciseRow(templateExercise: templateExercise)
                        }
                        .onDelete(perform: deleteExercises)
                        .onMove(perform: moveExercises)
                    }
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }
                .listRowBackground(Color.white.opacity(0.08))
            }
            .curveScrollBackground()
        }
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
                    Button("Save") { dismiss() }
                        .disabled(template.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                let templateExercise = TemplateExercise(exercise: exercise, order: template.sortedExercises.count)
                templateExercise.template = template
                context.insert(templateExercise)
            }
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = template.sortedExercises
        for index in offsets {
            context.delete(sorted[index])
        }
        reindex()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = template.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() {
            exercise.order = index
        }
    }

    private func reindex() {
        for (index, exercise) in template.sortedExercises.enumerated() {
            exercise.order = index
        }
    }
}

private struct TemplateExerciseRow: View {
    @Bindable var templateExercise: TemplateExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(templateExercise.displayName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                MuscleGroupChip(muscleGroup: templateExercise.muscleGroup)
            }
            HStack(spacing: 16) {
                Stepper("\(templateExercise.targetSets) sets", value: $templateExercise.targetSets, in: 1...10)
                Stepper("\(templateExercise.targetReps) reps", value: $templateExercise.targetReps, in: 1...50)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

private struct IconPicker: View {
    @Binding var selection: String
    private let icons = [
        "figure.strengthtraining.traditional", "figure.strengthtraining.functional",
        "figure.arms.open", "figure.core.training", "figure.rower",
        "figure.run", "figure.squat", "dumbbell.fill", "figure.mixed.cardio",
        "figure.boxing",
    ]

    var body: some View {
        Picker("Icon", selection: $selection) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon).tag(icon)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateEditorView(template: WorkoutTemplate(name: "Leg Day"))
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
