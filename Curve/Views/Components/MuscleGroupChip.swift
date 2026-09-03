import SwiftUI

struct MuscleGroupChip: View {
    let muscleGroup: MuscleGroup
    var isSelected: Bool = false

    var body: some View {
        Label(muscleGroup.displayName, systemImage: muscleGroup.symbolName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? muscleGroup.color : muscleGroup.color.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : muscleGroup.color)
    }
}

#Preview {
    HStack {
        MuscleGroupChip(muscleGroup: .chest)
        MuscleGroupChip(muscleGroup: .back, isSelected: true)
    }
}
