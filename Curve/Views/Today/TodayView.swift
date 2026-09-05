import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @AppStorage("userName") private var userName = ""
    @AppStorage("weeklyGoal") private var weeklyGoal = 4

    @State private var activeSession: WorkoutSession?
    @State private var showingStartSheet = false

    private var completedSessions: [WorkoutSession] { sessions.filter { !$0.isInProgress } }
    private var inProgressSession: WorkoutSession? { sessions.first { $0.isInProgress } }

    private var streakResult: WeeklyStreakResult {
        StreakEngine.calculate(sessions: sessions, weeklyGoal: weeklyGoal)
    }

    private var todaysCompletedSession: WorkoutSession? {
        completedSessions.first { $0.startedAt.isToday }
    }

    private var thisWeekSessions: [WorkoutSession] {
        let start = Date.now.startOfWeek()
        return completedSessions.filter { $0.startedAt >= start }
    }

    private var thisWeekVolume: Double { thisWeekSessions.reduce(0) { $0 + $1.totalVolume } }
    private var thisWeekActiveTime: TimeInterval { thisWeekSessions.reduce(0) { $0 + $1.duration } }
    private var thisWeekSets: Int { thisWeekSessions.reduce(0) { $0 + $1.totalSets } }

    private var suggestedTemplate: WorkoutTemplate? {
        guard let lastName = completedSessions.first?.templateNameSnapshot else { return templates.first }
        return templates.first { $0.name == lastName } ?? templates.first
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var initials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "🙂" }
        let parts = trimmed.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                heroCard

                if streakResult.freezesAvailable > 0 {
                    freezeNote
                }

                HStack(spacing: 10) {
                    StatCard(title: "Volume", value: "\(Int(thisWeekVolume)) lb", icon: "scalemass.fill")
                    StatCard(title: "Active time", value: thisWeekActiveTime.formattedDuration(), icon: "clock.fill")
                    StatCard(title: "Sets", value: "\(thisWeekSets)", icon: "checkmark.circle.fill")
                }

                Text("Today's workout")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CurveTheme.textPrimary)
                    .padding(.top, 4)

                todaysWorkoutCard

                if !completedSessions.isEmpty {
                    Text("Recent activity")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CurveTheme.textPrimary)
                        .padding(.top, 4)

                    VStack(spacing: 10) {
                        ForEach(completedSessions.prefix(3)) { session in
                            recentRow(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 110)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
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
            VStack(alignment: .leading, spacing: 1) {
                Text(greeting)
                    .font(.curveEyebrow())
                    .foregroundStyle(CurveTheme.textSecondary)
                Text(userName.isEmpty ? "there" : userName)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(CurveTheme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle().fill(CurveTheme.glossyIconFill)
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)
            .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
        }
    }

    private var heroCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("WEEK STREAK")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(CurveTheme.textSecondary)
                Text("\(streakResult.streakWeeks)")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Goal: \(weeklyGoal) workouts / week")
                    .font(.curveEyebrow(13))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            Spacer()
            RingProgressView(
                progress: Double(streakResult.thisWeekCount) / Double(max(weeklyGoal, 1)),
                primaryText: "\(min(streakResult.thisWeekCount, weeklyGoal))/\(weeklyGoal)",
                secondaryText: "This week"
            )
        }
        .glassCard()
    }

    private var freezeNote: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(CurveTheme.glossyIconFill)
                Image(systemName: "snowflake")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)
            Text("\(streakResult.freezesAvailable) streak freeze\(streakResult.freezesAvailable == 1 ? "" : "s") available if you miss a week")
                .font(.curveEyebrow(12.5))
                .foregroundStyle(CurveTheme.textSecondary)
            Spacer()
        }
        .glassCard(cornerRadius: 18, padding: 12)
    }

    @ViewBuilder
    private var todaysWorkoutCard: some View {
        if let inProgressSession {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(inProgressSession.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(inProgressSession.sortedExercises.count) exercises · in progress")
                            .font(.system(size: 12))
                            .foregroundStyle(CurveTheme.textSecondary)
                    }
                    Spacer()
                    tagPill("In Progress")
                }
                progressBar(inProgressSession.totalSets, total: max(inProgressSession.sortedExercises.flatMap { $0.sortedSets }.count, 1))
                Button("Resume workout") { activeSession = inProgressSession }
                    .buttonStyle(.curveChrome)
            }
            .glassCard()
            .contextMenu {
                Button(role: .destructive) {
                    context.delete(inProgressSession)
                } label: {
                    Label("Discard Workout", systemImage: "trash")
                }
            }
        } else if let todaysCompletedSession {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(todaysCompletedSession.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(todaysCompletedSession.totalSets) sets · \(todaysCompletedSession.duration.formattedDuration())")
                            .font(.system(size: 12))
                            .foregroundStyle(CurveTheme.textSecondary)
                    }
                    Spacer()
                    tagPill("Complete")
                }
                Label("Nice work — you trained today.", systemImage: "checkmark.seal.fill")
                    .font(.curveEyebrow(12.5))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            .glassCard()
        } else if let suggestedTemplate {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestedTemplate.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(suggestedTemplate.sortedExercises.count) exercises · Suggested")
                            .font(.system(size: 12))
                            .foregroundStyle(CurveTheme.textSecondary)
                    }
                    Spacer()
                    tagPill("Planned")
                }
                Button("Start workout") { startWorkout(from: suggestedTemplate) }
                    .buttonStyle(.curveChrome)
            }
            .glassCard()
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("No workout planned")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("Start an empty workout or save a template first.")
                    .font(.system(size: 12))
                    .foregroundStyle(CurveTheme.textSecondary)
                Button("Start workout") { showingStartSheet = true }
                    .buttonStyle(.curveChrome)
            }
            .glassCard()
        }
    }

    private func tagPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.22)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1))
    }

    private func progressBar(_ value: Int, total: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule().fill(CurveTheme.progressFill)
                    .frame(width: geo.size.width * min(Double(value) / Double(total), 1))
            }
        }
        .frame(height: 5)
    }

    private func recentRow(_ session: WorkoutSession) -> some View {
        NavigationLink {
            WorkoutDetailView(session: session)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CurveTheme.glossyIconFill)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(session.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(session.startedAt.isToday ? "Today" : session.startedAt.formattedShort()), \(session.totalSets) sets")
                        .font(.curveEyebrow(12))
                        .foregroundStyle(CurveTheme.textTertiary)
                }
                Spacer()
                Text(session.duration.formattedDuration())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .glassCard(cornerRadius: 18, padding: 13)
        }
        .buttonStyle(.plain)
    }

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

#Preview {
    NavigationStack {
        TodayView()
    }
    .modelContainer(PreviewData.container)
}
