import Foundation
import Observation

@Observable
final class RestTimerModel {
    var totalSeconds: Int = 0
    var remainingSeconds: Int = 0
    var isRunning: Bool = false

    private var timer: Timer?

    func start(seconds: Int) {
        stop()
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.stop()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
    }

    func addTime(_ seconds: Int) {
        remainingSeconds = max(0, remainingSeconds + seconds)
        totalSeconds = max(totalSeconds, remainingSeconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }
}
