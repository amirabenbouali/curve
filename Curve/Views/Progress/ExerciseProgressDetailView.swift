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

    private var personalBest: Double {
        dataPoints.map(\.topWeight).max() ?? 0
    }

    private var latestWeight: Double {
        dataPoints.last?.topWeight ?? 0
    }

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(title: "Personal Best", value: "\(personalBest.formattedWeight()) lb", icon: "trophy.fill", tint: .yellow)
                    StatCard(title: "Latest", value: "\(latestWeight.formattedWeight()) lb", icon: "clock.arrow.circlepath")
                }
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Top Set Weight") {
                if dataPoints.count >= 2 {
                    Chart(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.topWeight)
                        )
                        .interpolationMethod(.catmullRom)
                        .symbol(.circle)
                        .foregroundStyle(Color.accentColor)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.topWeight)
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 200)
                } else {
                    Text("Log this exercise at least twice to see a trend.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Estimated 1-Rep Max") {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.estimatedOneRepMax)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.purple)
                }
                .frame(height: 160)
            }

            Section("Volume per Session") {
                Chart(dataPoints) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(.teal)
                    .cornerRadius(3)
                }
                .frame(height: 160)
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressDetailView(exerciseName: "Back Squat", sessions: [])
    }
    .modelContainer(PreviewData.container)
}
