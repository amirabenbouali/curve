import SwiftUI
import SwiftData

struct TemplatesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showingNewTemplate: WorkoutTemplate?

    var body: some View {
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
                List {
                    ForEach(templates) { template in
                        NavigationLink(value: template) {
                            TemplateRow(template: template)
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createTemplate()
                } label: {
                    Image(systemName: "plus")
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
        }
    }

    private func createTemplate() {
        let template = WorkoutTemplate(name: "New Template")
        context.insert(template)
        showingNewTemplate = template
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            context.delete(templates[index])
        }
    }
}

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: template.iconName)
                    .foregroundStyle(Color.accentColor)
                Text(template.name)
                    .font(.headline)
            }
            Text("\(template.sortedExercises.count) exercises")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TemplatesListView()
    }
    .modelContainer(PreviewData.container)
}
