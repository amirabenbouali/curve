import SwiftUI

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let setNumber: Int
    var onCommit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(set.isWarmup ? "W" : "\(setNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(set.isWarmup ? .orange : .secondary)
                .frame(width: 24)

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
                .onChange(of: set.weight) { onCommit?() }

            Text("lb")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 56)
                .onChange(of: set.reps) { onCommit?() }

            Text("reps")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                set.isCompleted.toggle()
                onCommit?()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
