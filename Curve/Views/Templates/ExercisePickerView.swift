import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    var onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @State private var showingAddCustom = false

    private var filtered: [Exercise] {
        allExercises.filter { exercise in
            let matchesGroup = selectedGroup == nil || exercise.muscleGroup == selectedGroup
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            return matchesGroup && matchesSearch
        }
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let groups = Dictionary(grouping: filtered) { $0.muscleGroup }
        return MuscleGroup.allCases.compactMap { group in
            guard let items = groups[group], !items.isEmpty else { return nil }
            return (group, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedGroup == nil) {
                                selectedGroup = nil
                            }
                            ForEach(MuscleGroup.allCases) { group in
                                FilterChip(title: group.displayName, isSelected: selectedGroup == group) {
                                    selectedGroup = selectedGroup == group ? nil : group
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    List {
                        ForEach(groupedExercises, id: \.0) { group, exercises in
                            Section(group.displayName) {
                                ForEach(exercises) { exercise in
                                    Button {
                                        onSelect(exercise)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Text(exercise.name)
                                                .foregroundStyle(.white)
                                            if exercise.isCustom {
                                                Text("Custom")
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.7))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(.white.opacity(0.15)))
                                            }
                                            Spacer()
                                        }
                                    }
                                    .listRowBackground(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .curveScrollBackground()
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingAddCustom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCustom) {
                AddCustomExerciseSheet { exercise in
                    onSelect(exercise)
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.14)))
                .overlay(Capsule().strokeBorder(.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1))
                .foregroundStyle(isSelected ? Color(red: 0.078, green: 0.129, blue: 0.114) : .white)
        }
    }
}

private struct AddCustomExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .fullBody
    var onCreate: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                Form {
                    TextField("Exercise name", text: $name)
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                }
                .curveScrollBackground()
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = Exercise(name: name.trimmingCharacters(in: .whitespaces), muscleGroup: muscleGroup, isCustom: true)
                        context.insert(exercise)
                        onCreate(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
