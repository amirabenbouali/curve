import SwiftUI
import SwiftData

private enum ProgressRange: String, CaseIterable {
    case month = "Month", week = "Week", year = "Year"

    var subtitle: String {
        switch self {
        case .week: return "Last 8 weeks"
        case .month: return "Last 8 months"
        case .year: return "Last 5 years"
        }
    }
}

struct ProgressDashboardView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]
    @AppStorage("weeklyGoal") private var weeklyGoal = 4

    @State private var selectedRange: ProgressRange = .week

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { !$0.isInProgress }
    }

    private var streakResult: WeeklyStreakResult {
        StreakEngine.calculate(sessions: allSessions, weeklyGoal: weeklyGoal)
    }

    private var chartBars: [PeriodBar] {
        switch selectedRange {
        case .week:
            return StreakEngine.weeklyBreakdown(sessions: allSessions, weeklyGoal: weeklyGoal, weeksToShow: 8)
        case .month:
            return StreakEngine.periodBreakdown(sessions: allSessions, weeklyGoal: weeklyGoal, component: .month, periodsToShow: 8)
        case .year:
            return StreakEngine.periodBreakdown(sessions: allSessions, weeklyGoal: weeklyGoal, component: .year, periodsToShow: 5)
        }
    }

    private var chartGoalThreshold: Int {
        switch selectedRange {
        case .week: return weeklyGoal
        case .month: return weeklyGoal * 4
        case .year: return weeklyGoal * 52
        }
    }

    private var totalTime: TimeInterval {
        completedSessions.reduce(0) { $0 + $1.duration }
    }

    private var avgSessionTime: TimeInterval {
        completedSessions.isEmpty ? 0 : totalTime / Double(completedSessions.count)
    }

    private var personalRecords: [PersonalRecord] {
        PersonalRecordEngine.currentRecords(sessions: allSessions)
    }

    private var prsThisMonth: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        return personalRecords.filter { $0.date >= cutoff }.count
    }

    private var bodyFocus: [(BodyRegion, Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        var counts: [BodyRegion: Int] = [:]
        var total = 0
        for session in completedSessions where session.startedAt >= cutoff {
            for exercise in session.sortedExercises {
                let completedCount = exercise.sortedSets.filter { $0.isCompleted }.count
                guard completedCount > 0 else { continue }
                counts[BodyRegion.region(for: exercise.muscleGroup), default: 0] += completedCount
                total += completedCount
            }
        }
        guard total > 0 else { return [] }
        return counts
            .map { ($0.key, Double($0.value) / Double(total)) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
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
                            header
                            streakStrip
                            chartCard

                            HStack(spacing: 10) {
                                statBlock(value: "\(completedSessions.count)", label: "Total workouts")
                                statBlock(value: totalTime.formattedDuration(), label: "Total time")
                            }
                            HStack(spacing: 10) {
                                statBlock(value: avgSessionTime.formattedDuration(), label: "Avg session")
                                statBlock(value: "\(prsThisMonth)", label: "PRs this month")
                            }

                            if !bodyFocus.isEmpty {
                                Text("Body Focus")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.top, 4)
                                bodyFocusCard
                            }

                            if !personalRecords.isEmpty {
                                Text("Personal Records")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.top, 4)
                                VStack(spacing: 8) {
                                    ForEach(personalRecords.prefix(6)) { record in
                                        NavigationLink {
                                            ExerciseProgressDetailView(exerciseName: record.exerciseName, sessions: completedSessions)
                                        } label: {
                                            prRow(record)
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
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Progress")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                Text(selectedRange.subtitle)
                    .font(.curveEyebrow(13))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(ProgressRange.allCases, id: \.self) { range in
                    Button {
                        selectedRange = range
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 11.5, weight: .semibold))
                            .fixedSize()
                            .foregroundStyle(selectedRange == range ? .white : .white.opacity(0.55))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedRange == range ? .white.opacity(0.22) : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .glassCard(cornerRadius: 20, padding: 0)
        }
        .padding(.top, 8)
    }

    // MARK: - Streak strip

    private var streakStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(streakResult.streakWeeks) week streak")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("Goal: \(weeklyGoal) workouts / week")
                    .font(.curveEyebrow(12))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedRange == .week ? "Workouts per week" : selectedRange == .month ? "Workouts per month" : "Workouts per year")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CurveTheme.textSecondary)
            WorkoutBarChart(bars: chartBars, goalThreshold: chartGoalThreshold)
        }
        .glassCard()
    }

    // MARK: - Stats

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CurveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18, padding: 16)
    }

    // MARK: - Body focus

    private var bodyFocusCard: some View {
        VStack(spacing: 12) {
            ForEach(bodyFocus, id: \.0) { region, fraction in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(region.rawValue)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(CurveTheme.textSecondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.14))
                            Capsule().fill(CurveTheme.progressFill)
                                .frame(width: geo.size.width * fraction)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Personal records

    private func prRow(_ record: PersonalRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(CurveTheme.glossyIconFill)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.yellow)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(record.exerciseName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                Text(record.date.relativeDescription())
                    .font(.curveEyebrow(12))
                    .foregroundStyle(CurveTheme.textTertiary)
            }
            Spacer()
            Text("\(record.weight.formattedWeight()) lb × \(record.reps)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .glassCard(cornerRadius: 18, padding: 13)
    }
}

// MARK: - Bar chart

private struct WorkoutBarChart: View {
    let bars: [PeriodBar]
    let goalThreshold: Int
    private let chartHeight: CGFloat = 130

    private var maxScale: Double {
        Double(max(goalThreshold, bars.map(\.count).max() ?? 0, 1))
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                GeometryReader { geo in
                    let goalFraction = min(Double(goalThreshold) / maxScale, 1)
                    Path { path in
                        let y = geo.size.height * (1 - goalFraction)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.white.opacity(0.4))
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(bars) { bar in
                        barView(bar)
                    }
                }
            }
            .frame(height: chartHeight)

            HStack(spacing: 8) {
                ForEach(bars) { bar in
                    Text(bar.label)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func barView(_ bar: PeriodBar) -> some View {
        let fraction = min(Double(bar.count) / maxScale, 1)
        VStack(spacing: 4) {
            Image(systemName: "snowflake")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .opacity(bar.usedFreeze ? 1 : 0)
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(barFill(bar))
                .frame(height: max(chartHeight * CGFloat(fraction) - 20, 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(bar.isCurrent ? .white.opacity(0.6) : .clear, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func barFill(_ bar: PeriodBar) -> AnyShapeStyle {
        if bar.isCurrent { return AnyShapeStyle(.white.opacity(0.35)) }
        if bar.metGoal {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.949, green: 0.941, blue: 0.914), Color(red: 0.576, green: 0.659, blue: 0.612)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        return AnyShapeStyle(.white.opacity(0.18))
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
