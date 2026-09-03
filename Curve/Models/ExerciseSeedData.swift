import Foundation
import SwiftData

enum ExerciseSeedData {
    static let library: [(String, MuscleGroup)] = [
        // Chest
        ("Barbell Bench Press", .chest),
        ("Incline Dumbbell Press", .chest),
        ("Dumbbell Fly", .chest),
        ("Push-Up", .chest),
        ("Cable Crossover", .chest),
        ("Dips", .chest),
        // Back
        ("Deadlift", .back),
        ("Pull-Up", .back),
        ("Barbell Row", .back),
        ("Lat Pulldown", .back),
        ("Seated Cable Row", .back),
        ("T-Bar Row", .back),
        // Shoulders
        ("Overhead Press", .shoulders),
        ("Dumbbell Shoulder Press", .shoulders),
        ("Lateral Raise", .shoulders),
        ("Front Raise", .shoulders),
        ("Face Pull", .shoulders),
        ("Arnold Press", .shoulders),
        // Biceps
        ("Barbell Curl", .biceps),
        ("Dumbbell Curl", .biceps),
        ("Hammer Curl", .biceps),
        ("Preacher Curl", .biceps),
        // Triceps
        ("Tricep Pushdown", .triceps),
        ("Skull Crusher", .triceps),
        ("Close-Grip Bench Press", .triceps),
        ("Overhead Tricep Extension", .triceps),
        // Forearms
        ("Wrist Curl", .forearms),
        ("Farmer's Carry", .forearms),
        // Abs
        ("Plank", .abs),
        ("Crunch", .abs),
        ("Hanging Leg Raise", .abs),
        ("Cable Woodchop", .abs),
        ("Ab Rollout", .abs),
        // Quads
        ("Back Squat", .quads),
        ("Front Squat", .quads),
        ("Leg Press", .quads),
        ("Leg Extension", .quads),
        ("Walking Lunge", .quads),
        // Hamstrings
        ("Romanian Deadlift", .hamstrings),
        ("Leg Curl", .hamstrings),
        ("Good Morning", .hamstrings),
        // Glutes
        ("Hip Thrust", .glutes),
        ("Glute Bridge", .glutes),
        ("Cable Kickback", .glutes),
        // Calves
        ("Standing Calf Raise", .calves),
        ("Seated Calf Raise", .calves),
        // Cardio
        ("Treadmill Run", .cardio),
        ("Rowing Machine", .cardio),
        ("Stationary Bike", .cardio),
        ("Jump Rope", .cardio),
        // Full Body
        ("Kettlebell Swing", .fullBody),
        ("Burpee", .fullBody),
        ("Clean and Jerk", .fullBody),
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (name, group) in library {
            context.insert(Exercise(name: name, muscleGroup: group))
        }
        try? context.save()
    }
}
