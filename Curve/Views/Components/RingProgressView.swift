import SwiftUI

struct RingProgressView: View {
    let progress: Double
    let primaryText: String
    let secondaryText: String
    var size: CGFloat = 82

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 7)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(CurveTheme.chrome, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color(red: 0.059, green: 0.078, blue: 0.071).opacity(0.82))
                .padding(7)
            VStack(spacing: 1) {
                Text(primaryText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(secondaryText)
                    .font(.system(size: 8.5, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        CurveBackground()
        RingProgressView(progress: 0.75, primaryText: "3/4", secondaryText: "This week")
    }
}
