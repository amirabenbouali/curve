import Foundation

enum BodyRegion: String, CaseIterable, Identifiable {
    case legs = "Legs"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case other = "Other"

    var id: String { rawValue }

    static func region(for muscleGroup: MuscleGroup) -> BodyRegion {
        switch muscleGroup {
        case .quads, .hamstrings, .glutes, .calves: return .legs
        case .chest: return .chest
        case .back: return .back
        case .shoulders: return .shoulders
        case .biceps, .triceps, .forearms: return .arms
        case .abs: return .core
        case .cardio, .fullBody: return .other
        }
    }
}
