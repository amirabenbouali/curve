import SwiftUI

struct RestTimerBar: View {
    @Bindable var timer: RestTimerModel

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(timer.remainingSeconds)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            Text("Resting…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                timer.addTime(-15)
            } label: {
                Text("-15s")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }

            Button {
                timer.addTime(15)
            } label: {
                Text("+15s")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }

            Button {
                timer.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor))
        .padding(.horizontal)
    }
}
