import SwiftUI
import SwiftData

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showingStartSheet = false
    @State private var activeSession: WorkoutSession?

    private var inProgressSession: WorkoutSession? {
        sessions.first { $0.isInProgress }
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter { !$0.isInProgress }
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    icon: "dumbbell",
                    title: "No Workouts Yet",
                    message: "Start your first workout to begin tracking sets, reps, and weight.",
                    actionTitle: "Start Workout"
                ) {
                    showingStartSheet = true
                }
            } else {
                List {
                    if let inProgressSession {
                        Section {
                            Button {
                                activeSession = inProgressSession
                            } label: {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(inProgressSession.name)
                                            .font(.headline)
                                        Text("Workout in progress — tap to resume")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Section("History") {
                        ForEach(completedSessions) { session in
                            NavigationLink(value: session) {
                                WorkoutSessionRow(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStartSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: WorkoutSession.self) { session in
            WorkoutDetailView(session: session)
        }
        .sheet(isPresented: $showingStartSheet) {
            StartWorkoutSheet(templates: templates) { session in
                activeSession = session
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            NavigationStack {
                ActiveWorkoutView(session: session)
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            context.delete(completedSessions[index])
        }
    }
}

private struct WorkoutSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name)
                    .font(.headline)
                Spacer()
                Text(session.startedAt.formattedShort())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label(session.duration.formattedDuration(), systemImage: "clock")
                Label("\(session.totalSets) sets", systemImage: "number")
                Label("\(Int(session.totalVolume)) lb vol", systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView()
    }
    .modelContainer(PreviewData.container)
}
