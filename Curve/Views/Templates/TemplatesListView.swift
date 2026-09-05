import SwiftUI
import SwiftData

struct TemplatesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showingNewTemplate: WorkoutTemplate?

    var body: some View {
        ZStack {
            CurveBackground()
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
                            NavigationLink(value: template) {
                                TemplateRow(template: template)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
            }
            }
        }
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
    }

    private func createTemplate() {
        let template = WorkoutTemplate(name: "New Template")
        context.insert(template)
        showingNewTemplate = template
    }
}

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle().fill(.white.opacity(0.16))
                    Image(systemName: template.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
                Text(template.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("\(template.sortedExercises.count) exercise\(template.sortedExercises.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(CurveTheme.textTertiary)
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
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

#Preview {
    NavigationStack {
        TemplatesListView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
