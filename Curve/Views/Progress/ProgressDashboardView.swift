import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @AppStorage("weeklyGoal") private var weeklyGoal = 4

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { !$0.isInProgress }
    }

    private var streakResult: WeeklyStreakResult {
        StreakEngine.calculate(sessions: allSessions, weeklyGoal: weeklyGoal)
    }

    private var muscleGroupSetCounts: [(MuscleGroup, Int)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        var counts: [MuscleGroup: Int] = [:]
        for session in completedSessions where session.startedAt >= cutoff {
            for exercise in session.sortedExercises {
                let completed = exercise.sortedSets.filter { $0.isCompleted }.count
                counts[exercise.muscleGroup, default: 0] += completed
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var loggedExerciseNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for session in completedSessions {
            for exercise in session.sortedExercises {
                if seen.insert(exercise.displayName).inserted {
                    names.append(exercise.displayName)
                }
            }
        }
        return names
    }

    var body: some View {
        ZStack {
            CurveBackground()
            Group {
            if completedSessions.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Progress Yet",
                    message: "Complete a workout to start seeing your strength trends here."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            StatCard(title: "Week streak", value: "\(streakResult.streakWeeks)", icon: "flame.fill", tint: .orange)
                            StatCard(title: "This week", value: "\(streakResult.thisWeekCount)/\(weeklyGoal)", icon: "calendar")
                        }

                        if !muscleGroupSetCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Muscle Group Focus (30 days)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CurveTheme.textSecondary)
                                Chart(muscleGroupSetCounts, id: \.0) { group, count in
                                    BarMark(
                                        x: .value("Sets", count),
                                        y: .value("Muscle Group", group.displayName)
                                    )
                                    .foregroundStyle(group.color)
                                    .cornerRadius(4)
                                }
                                .chartXAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
                                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
                                .frame(height: CGFloat(muscleGroupSetCounts.count) * 32 + 20)
                            }
                            .glassCard()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weekly Consistency")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CurveTheme.textSecondary)
                            WeeklyConsistencyChart(sessions: completedSessions)
                                .frame(height: 150)
                        }
                        .glassCard()

                        if !loggedExerciseNames.isEmpty {
                            Text("Strength Progression")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(CurveTheme.textPrimary)
                                .padding(.top, 4)

                            VStack(spacing: 10) {
                                ForEach(loggedExerciseNames, id: \.self) { name in
                                    NavigationLink {
                                        ExerciseProgressDetailView(exerciseName: name, sessions: completedSessions)
                                    } label: {
                                        HStack {
                                            Text(name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(CurveTheme.textTertiary)
                                        }
                                        .glassCard(cornerRadius: 18, padding: 14)
                                    }
                                    .buttonStyle(.plain)
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
        .navigationTitle("Progress")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct WeeklyConsistencyChart: View {
    let sessions: [WorkoutSession]

    private var weeklyData: [(Date, Int)] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? .distantPast
        var counts: [Date: Int] = [:]
        for session in sessions where session.startedAt >= cutoff {
            let week = session.startedAt.startOfWeek(using: calendar)
            counts[week, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }
    }

    var body: some View {
        Chart(weeklyData, id: \.0) { week, count in
            BarMark(
                x: .value("Week", week, unit: .weekOfYear),
                y: .value("Workouts", count)
            )
            .foregroundStyle(CurveTheme.chrome)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                AxisGridLine().foregroundStyle(CurveTheme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day()).foregroundStyle(CurveTheme.textSecondary)
            }
        }
        .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
