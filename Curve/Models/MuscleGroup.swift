import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case abs
    case quads
    case hamstrings
    case glutes
    case calves
    case cardio
    case fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }

    var symbolName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.boxing"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "dumbbell.fill"
        case .forearms: return "hand.raised.fill"
        case .abs: return "figure.core.training"
        case .quads: return "figure.squat"
        case .hamstrings: return "figure.squat"
        case .glutes: return "figure.step.training"
        case .calves: return "figure.walk"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .biceps: return .purple
        case .triceps: return .pink
        case .forearms: return .brown
        case .abs: return .yellow
        case .quads: return .green
        case .hamstrings: return .mint
        case .glutes: return .indigo
        case .calves: return .teal
        case .cardio: return .cyan
        case .fullBody: return .gray
        }
    }
}
