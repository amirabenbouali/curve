import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(.white.opacity(0.12)).frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(CurveTheme.textSecondary)
            }
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CurveTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(CurveTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.curveChrome)
                    .frame(maxWidth: 220)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        CurveBackground()
        EmptyStateView(icon: "dumbbell", title: "No Workouts Yet", message: "Start your first workout to begin tracking progress.", actionTitle: "Start Workout") {}
    }
}
