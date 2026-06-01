import Foundation

struct LFOState {
    var isEnabled: Bool = false
    var period: Double = 60.0  // seconds, clamped 30...1800
}

class LFOManager: ObservableObject {
    let bandCount: Int
    @Published var states: [LFOState]

    var baseGains: [Float] = []
    var onEffectiveGainsUpdated: (([Float]) -> Void)?

    private var playStartTime: Date? = nil
    private var timer: Timer?

    init(bandCount: Int) {
        self.bandCount = bandCount
        self.states = Array(repeating: LFOState(), count: bandCount)
    }

    func setPlaying(_ playing: Bool, currentGains: [Float]) {
        if playing {
            if playStartTime == nil { playStartTime = Date() }
            startTimer()
        } else {
            stopTimer()
            playStartTime = nil
            onEffectiveGainsUpdated?(currentGains)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let startTime = playStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        var effective = baseGains
        guard effective.count >= bandCount else { return }

        for i in 0..<bandCount {
            guard states[i].isEnabled else { continue }
            let phase = (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0) * 2.0 * .pi
            effective[i] = Float(0.5 + 0.5 * sin(phase))
        }

        onEffectiveGainsUpdated?(effective)
    }

    func currentPhase(forBand i: Int) -> Double {
        guard let startTime = playStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0)
    }
}
