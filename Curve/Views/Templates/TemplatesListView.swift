import SwiftUI
import SwiftData

struct TemplatesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showingNewTemplate: WorkoutTemplate?
    @State private var activeSession: WorkoutSession?

    var body: some View {
        ZStack {
            CurveBackground(palette: .plum)
            Group {
            if templates.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.up",
                    title: "No Templates Yet",
                    message: "Save reusable routines like \"Leg Day\" or \"Back & Abs\" to start workouts faster.",
                    actionTitle: "Create Template"
                ) {
                    createTemplate()
                }
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(templates) { template in
                            TemplateRow(template: template) {
                                startWorkout(from: template)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    SyncManager.deleteTemplate(id: template.id)
                                    context.delete(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            }
        }
        .environment(\.curvePalette, .plum)
        .navigationTitle("Templates")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createTemplate()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .navigationDestination(for: WorkoutTemplate.self) { template in
            TemplateEditorView(template: template)
        }
        .sheet(item: $showingNewTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template, isNew: true)
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $activeSession) { session in
            NavigationStack {
                ActiveWorkoutView(session: session)
            }
        }
    }

    private func createTemplate() {
        let template = WorkoutTemplate(name: "New Template")
        context.insert(template)
        showingNewTemplate = template
    }

    /// Mirrors TodayView.startWorkout(from:) — spins up a session pre-filled
    /// with the template's exercises and sets, skipping the editor entirely.
    private func startWorkout(from template: WorkoutTemplate) {
        let session = WorkoutSession(name: template.name, templateNameSnapshot: template.name)
        context.insert(session)
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
        try? context.save()
        activeSession = session
    }
}

private struct TemplateRow: View {
    let template: WorkoutTemplate
    var onStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink(value: template) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CurveTheme.glossyIconFill)
                        Image(systemName: template.iconName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(template.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(template.sortedExercises.count) exercise\(template.sortedExercises.count == 1 ? "" : "s")")
                            .font(.system(size: 11.5))
                            .foregroundStyle(CurveTheme.textSecondary)
                        if !template.muscleGroups.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(template.muscleGroups) { group in
                                        MuscleGroupChip(muscleGroup: group)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Color(hex: 0x14211D))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(CurveTheme.chrome))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1).blendMode(.overlay))
            }
            .buttonStyle(.plain)
            .disabled(template.sortedExercises.isEmpty)
            .opacity(template.sortedExercises.isEmpty ? 0.4 : 1)
        }
        .glassCard(cornerRadius: 24, padding: 14)
    }
}

#Preview {
    NavigationStack {
        TemplatesListView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
