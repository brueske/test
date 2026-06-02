import Foundation

struct LFOPoint {
    var t: Double  // 0...1 position in period
    var y: Double  // 0...1 gain level
}

struct LFOState {
    var isEnabled: Bool = false
    var period: Double = 60.0  // seconds, 30...1800
    var customPoints: [LFOPoint] = []  // empty = sine wave
}

// Accessible from LFOEditorView for curve drawing
func evaluateCurveValue(at t: Double, points: [LFOPoint]) -> Double {
    guard !points.isEmpty else {
        return 0.5 + 0.5 * sin(t * 2.0 * .pi)
    }
    let sorted = points.sorted { $0.t < $1.t }
    if t <= sorted.first!.t { return sorted.first!.y }
    if t >= sorted.last!.t { return sorted.last!.y }
    for i in 0..<sorted.count - 1 {
        let p0 = sorted[i], p1 = sorted[i + 1]
        guard t >= p0.t && t < p1.t else { continue }
        let lt = (p1.t - p0.t) > 0 ? (t - p0.t) / (p1.t - p0.t) : 0.0
        let y0 = i > 0 ? sorted[i-1].y : p0.y
        let y3 = i < sorted.count - 2 ? sorted[i+2].y : p1.y
        return catmullRomSpline(lt, y0, p0.y, p1.y, y3).clamped(to: 0...1)
    }
    return 0.5
}

private func catmullRomSpline(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> Double {
    0.5 * ((2*p1) + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t*t + (-p0+3*p1-3*p2+p3)*t*t*t)
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
            let t = (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0)
            effective[i] = Float(evaluateCurveValue(at: t, points: states[i].customPoints))
        }

        onEffectiveGainsUpdated?(effective)
    }

    func currentPhase(forBand i: Int) -> Double {
        guard let startTime = playStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0)
    }
}
