import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { !$0.isInProgress }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let workoutDays = Set(completedSessions.map { calendar.startOfDay(for: $0.startedAt) })
        guard !workoutDays.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: Date())
        if !workoutDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while workoutDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private var thisWeekCount: Int {
        let startOfWeek = Date().startOfWeek()
        return completedSessions.filter { $0.startedAt >= startOfWeek }.count
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
        Group {
            if completedSessions.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Progress Yet",
                    message: "Complete a workout to start seeing your strength trends here."
                )
            } else {
                List {
                    Section {
                        HStack {
                            StatCard(title: "Streak", value: "\(currentStreak) day\(currentStreak == 1 ? "" : "s")", icon: "flame.fill", tint: .orange)
                            StatCard(title: "This Week", value: "\(thisWeekCount) workout\(thisWeekCount == 1 ? "" : "s")", icon: "calendar", tint: .blue)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if !muscleGroupSetCounts.isEmpty {
                        Section("Muscle Group Focus (30 days)") {
                            Chart(muscleGroupSetCounts, id: \.0) { group, count in
                                BarMark(
                                    x: .value("Sets", count),
                                    y: .value("Muscle Group", group.displayName)
                                )
                                .foregroundStyle(group.color)
                                .cornerRadius(4)
                            }
                            .frame(height: CGFloat(muscleGroupSetCounts.count) * 32 + 20)
                        }
                    }

                    Section("Weekly Consistency") {
                        WeeklyConsistencyChart(sessions: completedSessions)
                            .frame(height: 160)
                    }

                    if !loggedExerciseNames.isEmpty {
                        Section("Strength Progression") {
                            ForEach(loggedExerciseNames, id: \.self) { name in
                                NavigationLink(name) {
                                    ExerciseProgressDetailView(exerciseName: name, sessions: completedSessions)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Progress")
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
            .foregroundStyle(Color.accentColor)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
    }
    .modelContainer(PreviewData.container)
}
