import SwiftUI

private enum OnboardingStep {
    case welcome, goal, units, allSet
}

struct OnboardingView: View {
    var onComplete: () -> Void

    @AppStorage("weeklyGoal") private var weeklyGoal = 4
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.lb.rawValue

    @State private var step: OnboardingStep = .welcome
    @State private var selectedGoal = 4
    @State private var selectedUnit: WeightUnit = .lb

    var body: some View {
        ZStack {
            CurveBackground()

            Group {
                switch step {
                case .welcome: welcomeScreen
                case .goal: goalScreen
                case .units: unitsScreen
                case .allSet: allSetScreen
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .preferredColorScheme(.dark)
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack {
            Spacer()
            VStack(spacing: 22) {
                CurveMark()
                VStack(spacing: 6) {
                    Text("Curve")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Every set, counted.")
                        .font(.curveEyebrow(15))
                        .foregroundStyle(CurveTheme.textSecondary)
                }
            }
            Spacer()
            Button("Get started") {
                step = .goal
            }
            .buttonStyle(.curveChrome)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    // MARK: - Screen 2: Weekly goal

    private var goalScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("STEP 1 OF 2")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(CurveTheme.textSecondary)

            Text("How many days a week do you want to train?")
                .font(.system(size: 23, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 10)

            Text("Your streak counts full weeks that hit this goal, not single days, so a missed Monday won't break it.")
                .font(.curveEyebrow(13.5))
                .foregroundStyle(CurveTheme.textSecondary)
                .padding(.top, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                goalCard(3, label: "3")
                goalCard(4, label: "4")
                goalCard(5, label: "5")
                goalCard(6, label: "6+")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") {
                weeklyGoal = selectedGoal
                step = .units
            }
            .buttonStyle(.curveChrome)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    private func goalCard(_ value: Int, label: String) -> some View {
        let isSelected = selectedGoal == value
        return Button {
            selectedGoal = value
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                Text("days / week")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCard(cornerRadius: 18, padding: 0)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.75) : .clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(.white)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color(red: 0.078, green: 0.129, blue: 0.114))
                    }
                    .frame(width: 20, height: 20)
                    .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Screen 3: Units

    private var unitsScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("STEP 2 OF 2")
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(CurveTheme.textSecondary)

            Text("Which units do you train in?")
                .font(.system(size: 23, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 10)

            Text("Used for every weight you log. You can change this anytime in Settings.")
                .font(.curveEyebrow(13.5))
                .foregroundStyle(CurveTheme.textSecondary)
                .padding(.top, 8)

            HStack(spacing: 12) {
                unitCard(.lb, title: "Pounds", subtitle: "lb")
                unitCard(.kg, title: "Kilograms", subtitle: "kg")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") {
                weightUnitRaw = selectedUnit.rawValue
                step = .allSet
            }
            .buttonStyle(.curveChrome)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    private func unitCard(_ unit: WeightUnit, title: String, subtitle: String) -> some View {
        let isSelected = selectedUnit == unit
        return Button {
            selectedUnit = unit
        } label: {
            VStack(spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCard(cornerRadius: 18, padding: 0)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.75) : .clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(.white)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color(red: 0.078, green: 0.129, blue: 0.114))
                    }
                    .frame(width: 20, height: 20)
                    .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Screen 4: All set

    private var allSetScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(CurveTheme.glossyIconFill)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 88, height: 88)
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))

            Text("You're all set")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 22)

            Text("Your first week starts now. Log a workout whenever you train, and Curve keeps the streak.")
                .font(.curveEyebrow(13.5))
                .foregroundStyle(CurveTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.top, 8)

            VStack(spacing: 10) {
                summaryRow("Weekly goal", "\(selectedGoal) workouts")
                summaryRow("Streak freezes", "Up to 2, earned over time")
                summaryRow("Units", selectedUnit == .kg ? "Kilograms" : "Pounds")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassCard(padding: 0)
            .padding(.top, 26)

            Spacer()

            Button("Start training") {
                onComplete()
            }
            .buttonStyle(.curveChrome)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12.5))
                .foregroundStyle(CurveTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct CurveMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.663, green: 0.741, blue: 0.698),
                        Color(red: 0.369, green: 0.431, blue: 0.404),
                        Color(red: 0.078, green: 0.129, blue: 0.114),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 8)
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1))

            HStack(spacing: 8) {
                bar(height: 30)
                bar(height: 46)
                bar(height: 22)
                bar(height: 38)
            }
            .rotationEffect(.degrees(-18))
        }
        .frame(width: 108, height: 108)
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(red: 0.961, green: 0.957, blue: 0.945))
            .frame(width: 11, height: height)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
