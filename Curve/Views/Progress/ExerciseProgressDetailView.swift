import SwiftUI
import Charts

struct ExerciseProgressDetailView: View {
    let exerciseName: String
    let sessions: [WorkoutSession]

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let topWeight: Double
        let estimatedOneRepMax: Double
        let volume: Double
    }

    private var dataPoints: [DataPoint] {
        sessions.compactMap { session -> DataPoint? in
            guard let logged = session.sortedExercises.first(where: { $0.displayName == exerciseName }) else { return nil }
            let completedSets = logged.sortedSets.filter { $0.isCompleted && !$0.isWarmup }
            guard !completedSets.isEmpty else { return nil }
            let topWeight = completedSets.map(\.weight).max() ?? 0
            let estimated1RM = completedSets.map(\.estimatedOneRepMax).max() ?? 0
            let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return DataPoint(date: session.startedAt, topWeight: topWeight, estimatedOneRepMax: estimated1RM, volume: volume)
        }
        .sorted { $0.date < $1.date }
    }

    private var personalBest: Double { dataPoints.map(\.topWeight).max() ?? 0 }
    private var latestWeight: Double { dataPoints.last?.topWeight ?? 0 }

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    StatCard(title: "Personal Best", value: "\(personalBest.formattedWeight()) lb", icon: "trophy.fill", tint: .yellow)
                    StatCard(title: "Latest", value: "\(latestWeight.formattedWeight()) lb", icon: "clock.arrow.circlepath")
                }

                chartCard(title: "Top Set Weight") {
                    if dataPoints.count >= 2 {
                        Chart(dataPoints) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Weight", point.topWeight))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(CurveTheme.chrome)
                            PointMark(x: .value("Date", point.date), y: .value("Weight", point.topWeight))
                                .foregroundStyle(.white)
                        }
                        .themedChartAxes()
                        .frame(height: 180)
                    } else {
                        Text("Log this exercise at least twice to see a trend.")
                            .foregroundStyle(CurveTheme.textSecondary)
                    }
                }

                chartCard(title: "Estimated 1-Rep Max") {
                    Chart(dataPoints) { point in
                        LineMark(x: .value("Date", point.date), y: .value("1RM", point.estimatedOneRepMax))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.mint)
                    }
                    .themedChartAxes()
                    .frame(height: 150)
                }

                chartCard(title: "Volume per Session") {
                    Chart(dataPoints) { point in
                        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Volume", point.volume))
                            .foregroundStyle(.teal)
                            .cornerRadius(3)
                    }
                    .themedChartAxes()
                    .frame(height: 150)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CurveTheme.textSecondary)
            content()
        }
        .glassCard()
    }
}

private extension View {
    func themedChartAxes() -> some View {
        self
            .chartXAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
            .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressDetailView(exerciseName: "Back Squat", sessions: [])
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
