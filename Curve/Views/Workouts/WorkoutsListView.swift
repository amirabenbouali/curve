import SwiftUI
import SwiftData

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showingStartSheet = false
    @State private var activeSession: WorkoutSession?
    @State private var showingSearch = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var inProgressSession: WorkoutSession? {
        sessions.first { $0.isInProgress }
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter { !$0.isInProgress }
    }

    private var filteredSessions: [WorkoutSession] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return completedSessions }
        return completedSessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var prSessionIDs: Set<UUID> {
        PersonalRecordEngine.sessionsWithPR(sessions: sessions)
    }

    private var groupedSessions: [(title: String, sessions: [WorkoutSession])] {
        let calendar = Calendar.current
        let thisWeekStart = Date.now.startOfWeek(using: calendar)
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart
        let currentYear = calendar.component(.year, from: .now)

        var thisWeek: [WorkoutSession] = []
        var lastWeek: [WorkoutSession] = []
        var olderBuckets: [String: [WorkoutSession]] = [:]
        var olderOrder: [String] = []

        for session in filteredSessions {
            let weekStart = session.startedAt.startOfWeek(using: calendar)
            if weekStart == thisWeekStart {
                thisWeek.append(session)
            } else if weekStart == lastWeekStart {
                lastWeek.append(session)
            } else {
                let year = calendar.component(.year, from: session.startedAt)
                let monthName = session.startedAt.formatted(.dateTime.month(.wide))
                let key = year == currentYear ? monthName : "\(monthName) \(year)"
                if olderBuckets[key] == nil {
                    olderBuckets[key] = []
                    olderOrder.append(key)
                }
                olderBuckets[key]?.append(session)
            }
        }

        var groups: [(String, [WorkoutSession])] = []
        if !thisWeek.isEmpty { groups.append(("This week", thisWeek)) }
        if !lastWeek.isEmpty { groups.append(("Last week", lastWeek)) }
        for key in olderOrder {
            if let items = olderBuckets[key] { groups.append((key, items)) }
        }
        return groups
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            header

                            if showingSearch {
                                searchField
                            }

                            if let inProgressSession {
                                inProgressBanner(inProgressSession)
                            }

                            if filteredSessions.isEmpty {
                                Text("No workouts match \u{201C}\(searchText)\u{201D}")
                                    .font(.subheadline)
                                    .foregroundStyle(CurveTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                            } else {
                                ForEach(groupedSessions, id: \.title) { group in
                                    Text(group.title.uppercased())
                                        .font(.system(size: 11.5, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(.white.opacity(0.55))
                                        .padding(.leading, 4)
                                        .padding(.top, 4)

                                    VStack(spacing: 8) {
                                        ForEach(group.sessions) { session in
                                            NavigationLink {
                                                WorkoutDetailView(session: session)
                                            } label: {
                                                LogRow(session: session, isPR: prSessionIDs.contains(session.id))
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
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 110)
                    }
                }
            }

            if !sessions.isEmpty {
                Button {
                    showingStartSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color(red: 0.078, green: 0.129, blue: 0.114))
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(CurveTheme.chrome))
                        .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1).blendMode(.overlay))
                        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 108)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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

    private var header: some View {
        HStack {
            Text("Log")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
            Spacer()
            Button {
                if showingSearch {
                    showingSearch = false
                    searchText = ""
                } else {
                    showingSearch = true
                    searchFocused = true
                }
            } label: {
                Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .glassCard(cornerRadius: 20, padding: 0)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CurveTheme.textTertiary)
            TextField("Search workouts", text: $searchText)
                .focused($searchFocused)
                .foregroundStyle(.white)
                .tint(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 16, padding: 0)
    }

    private func inProgressBanner(_ session: WorkoutSession) -> some View {
        Button {
            activeSession = session
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
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
        .contextMenu {
            Button(role: .destructive) {
                context.delete(session)
            } label: {
                Label("Discard Workout", systemImage: "trash")
            }
        }
    }
}

private struct LogRow: View {
    let session: WorkoutSession
    let isPR: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(session.startedAt.formatted(.dateTime.day(.twoDigits)))
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 46, height: 46)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(Int(session.duration / 60)) min, \(session.sortedExercises.count) exercise\(session.sortedExercises.count == 1 ? "" : "s")")
                    .font(.curveEyebrow(12))
                    .foregroundStyle(CurveTheme.textSecondary)
            }

            Spacer()

            if isPR {
                ZStack {
                    Circle().fill(CurveTheme.glossyIconFill)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.yellow)
                }
                .frame(width: 30, height: 30)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .glassCard(cornerRadius: 18, padding: 12)
    }
}

#Preview {
    NavigationStack {
        WorkoutsListView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
