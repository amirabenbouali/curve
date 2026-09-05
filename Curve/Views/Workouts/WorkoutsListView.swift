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
        ZStack {
            CurveBackground()
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let inProgressSession {
                            Button {
                                activeSession = inProgressSession
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(inProgressSession.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Workout in progress — tap to resume")
                                            .font(.caption)
                                            .foregroundStyle(CurveTheme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .glassCard(cornerRadius: 18, padding: 14)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("History")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CurveTheme.textPrimary)

                        VStack(spacing: 10) {
                            ForEach(completedSessions) { session in
                                NavigationLink {
                                    WorkoutDetailView(session: session)
                                } label: {
                                    WorkoutSessionRow(session: session)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
        .navigationTitle("Log")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStartSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
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
}

private struct WorkoutSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(session.startedAt.formattedShort())
                    .font(.caption)
                    .foregroundStyle(CurveTheme.textTertiary)
            }
            HStack(spacing: 14) {
                Label(session.duration.formattedDuration(), systemImage: "clock")
                Label("\(session.totalSets) sets", systemImage: "number")
                Label("\(Int(session.totalVolume)) lb", systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(CurveTheme.textSecondary)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
