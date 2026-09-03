import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(title: "Duration", value: session.duration.formattedDuration(), icon: "clock")
                    StatCard(title: "Sets", value: "\(session.totalSets)", icon: "number")
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
                HStack {
                    StatCard(title: "Volume", value: "\(Int(session.totalVolume)) lb", icon: "scalemass")
                    StatCard(title: "Date", value: session.startedAt.formattedShort(), icon: "calendar")
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(session.sortedExercises) { loggedExercise in
                Section {
                    ForEach(Array(loggedExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text(set.isWarmup ? "Warmup" : "Set \(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            Text("\(set.weight.formattedWeight()) lb × \(set.reps)")
                                .font(.subheadline)
                            Spacer()
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(loggedExercise.displayName)
                        Spacer()
                        MuscleGroupChip(muscleGroup: loggedExercise.muscleGroup)
                    }
                }
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(session: WorkoutSession(name: "Push Day"))
    }
    .modelContainer(PreviewData.container)
}
