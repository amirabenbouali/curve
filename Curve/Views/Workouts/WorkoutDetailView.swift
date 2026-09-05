import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.lb.rawValue
    let session: WorkoutSession
    @State private var showingDeleteConfirmation = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    StatCard(title: "Duration", value: session.duration.formattedDuration(), icon: "clock.fill")
                    StatCard(title: "Sets", value: "\(session.totalSets)", icon: "number")
                }
                HStack(spacing: 10) {
                    StatCard(title: "Volume", value: session.totalVolume.displayWeight(unit: weightUnit), icon: "scalemass.fill")
                    StatCard(title: "Date", value: session.startedAt.formattedShort(), icon: "calendar")
                }

                ForEach(session.sortedExercises) { loggedExercise in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(loggedExercise.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            MuscleGroupChip(muscleGroup: loggedExercise.muscleGroup)
                        }
                        VStack(spacing: 8) {
                            ForEach(Array(loggedExercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                                HStack {
                                    Text(set.isWarmup ? "Warmup" : "Set \(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(CurveTheme.textTertiary)
                                        .frame(width: 60, alignment: .leading)
                                    Text("\(set.weight.displayWeight(unit: weightUnit)) × \(set.reps)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if set.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                    .glassCard(cornerRadius: 18, padding: 14)
                }

                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CurveTheme.textSecondary)
                        Text(session.notes)
                            .foregroundStyle(.white)
                    }
                    .glassCard(cornerRadius: 18, padding: 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(session: WorkoutSession(name: "Push Day"))
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
