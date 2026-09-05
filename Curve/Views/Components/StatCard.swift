import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String? = nil
    var tint: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let icon {
                ZStack {
                    Circle().fill(.white.opacity(0.16))
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 28, height: 28)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(CurveTheme.textPrimary)
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(CurveTheme.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(CurveTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

#Preview {
    ZStack {
        CurveBackground()
        HStack {
            StatCard(title: "Streak", value: "4 days", icon: "flame.fill", tint: .orange)
            StatCard(title: "This Week", value: "3 workouts", icon: "calendar")
        }
        .padding()
    }
}
