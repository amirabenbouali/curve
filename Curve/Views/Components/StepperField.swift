import SwiftUI

/// Shared glass stepper control — a labeled value flanked by -/+ circle
/// buttons, used anywhere a set count, rep count, or weight needs quick
/// inline adjustment (Active Workout, Template Editor).
struct StepperFieldLayout<Value: View>: View {
    let label: String
    let unit: String
    let decrement: () -> Void
    let increment: () -> Void
    @ViewBuilder let value: Value

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                stepperButton("minus", action: decrement)
                value
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(minWidth: 38)
                stepperButton("plus", action: increment)
            }
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }

    private func stepperButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.white.opacity(0.16)))
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct IntStepperField: View {
    let label: String
    @Binding var value: Int
    var unit: String = ""
    var step: Int = 1
    var minValue: Int = 0

    var body: some View {
        StepperFieldLayout(
            label: label,
            unit: unit,
            decrement: { value = max(minValue, value - step) },
            increment: { value += step }
        ) {
            Text("\(value)")
        }
    }
}

struct DoubleStepperField: View {
    let label: String
    @Binding var value: Double
    var unit: String = ""
    var step: Double = 1
    var minValue: Double = 0

    var body: some View {
        StepperFieldLayout(
            label: label,
            unit: unit,
            decrement: { value = max(minValue, value - step) },
            increment: { value += step }
        ) {
            Text(value.formattedWeight())
        }
    }
}

#Preview {
    ZStack {
        CurveBackground(palette: .plum)
        HStack(spacing: 12) {
            IntStepperField(label: "SETS", value: .constant(4))
            IntStepperField(label: "REPS", value: .constant(10))
        }
        .padding()
    }
}
