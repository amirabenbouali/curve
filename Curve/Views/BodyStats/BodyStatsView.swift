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
                List {
                    Section {
                        HStack {
                            StatCard(title: "Current Weight", value: latestWeight.map { "\($0.formattedWeight()) lb" } ?? "—", icon: "scalemass")
                            if let weightChange {
                                StatCard(
                                    title: "Change",
                                    value: "\(weightChange > 0 ? "+" : "")\(weightChange.formattedWeight()) lb",
                                    icon: weightChange > 0 ? "arrow.up.right" : "arrow.down.right",
                                    tint: weightChange > 0 ? .orange : .green
                                )
                            }
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if weightEntries.count >= 2 {
                        Section("Weight Trend") {
                            Chart(weightEntries) { entry in
                                LineMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", entry.weight ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.accentColor)
                                .symbol(.circle)
                            }
                            .frame(height: 200)
                        }
                    }

                    Section("History") {
                        ForEach(entries) { entry in
                            BodyStatRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
        }
        .navigationTitle("Body Stats")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBodyStatSheet()
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            context.delete(entries[index])
        }
    }
}

private struct BodyStatRow: View {
    let entry: BodyStatEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.formattedFull())
                    .font(.subheadline.weight(.medium))
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let weight = entry.weight {
                    Text("\(weight.formattedWeight()) lb")
                        .font(.subheadline.weight(.semibold))
                }
                if let bodyFat = entry.bodyFatPercentage {
                    Text("\(bodyFat.formattedWeight())% BF")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        BodyStatsView()
    }
    .modelContainer(PreviewData.container)
}
