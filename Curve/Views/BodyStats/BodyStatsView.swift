import SwiftUI
import SwiftData
import Charts

struct BodyStatsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BodyStatEntry.date, order: .reverse) private var entries: [BodyStatEntry]

    @State private var showingAddSheet = false

    private var weightEntries: [BodyStatEntry] {
        entries.filter { $0.weight != nil }.sorted { $0.date < $1.date }
    }

    private var latestWeight: Double? {
        entries.first(where: { $0.weight != nil })?.weight
    }

    private var weightChange: Double? {
        guard weightEntries.count >= 2, let first = weightEntries.first?.weight, let last = weightEntries.last?.weight else { return nil }
        return last - first
    }

    var body: some View {
        ZStack {
            CurveBackground()
            Group {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "figure.stand",
                    title: "No Body Stats Yet",
                    message: "Log your weight and body fat percentage to track changes over time.",
                    actionTitle: "Add Entry"
                ) {
                    showingAddSheet = true
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            StatCard(title: "Current Weight", value: latestWeight.map { "\($0.formattedWeight()) lb" } ?? "—", icon: "scalemass.fill")
                            if let weightChange {
                                StatCard(
                                    title: "Change",
                                    value: "\(weightChange > 0 ? "+" : "")\(weightChange.formattedWeight()) lb",
                                    icon: weightChange > 0 ? "arrow.up.right" : "arrow.down.right",
                                    tint: weightChange > 0 ? .orange : .green
                                )
                            }
                        }

                        if weightEntries.count >= 2 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Weight Trend")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CurveTheme.textSecondary)
                                Chart(weightEntries) { entry in
                                    LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight ?? 0))
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(CurveTheme.chrome)
                                    PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight ?? 0))
                                        .foregroundStyle(.white)
                                }
                                .chartXAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
                                .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(CurveTheme.hairline); AxisValueLabel().foregroundStyle(CurveTheme.textSecondary) } }
                                .frame(height: 180)
                            }
                            .glassCard()
                        }

                        Text("History")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CurveTheme.textPrimary)
                            .padding(.top, 4)

                        VStack(spacing: 10) {
                            ForEach(entries) { entry in
                                BodyStatRow(entry: entry)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            context.delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            }
        }
        .navigationTitle("Body Stats")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBodyStatSheet()
        }
    }
}

private struct BodyStatRow: View {
    let entry: BodyStatEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.formattedFull())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(CurveTheme.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let weight = entry.weight {
                    Text("\(weight.formattedWeight()) lb")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                if let bodyFat = entry.bodyFatPercentage {
                    Text("\(bodyFat.formattedWeight())% BF")
                        .font(.caption)
                        .foregroundStyle(CurveTheme.textTertiary)
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

#Preview {
    NavigationStack {
        BodyStatsView()
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
