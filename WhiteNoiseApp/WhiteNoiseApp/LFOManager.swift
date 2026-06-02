import Foundation

struct LFOPoint: Codable {
    var t: Double  // 0...1 position in period
    var y: Double  // 0...1 gain level
}

struct LFOState: Codable {
    var isEnabled: Bool = false
    var period: Double = 60.0      // seconds, 30...1800
    var customPoints: [LFOPoint] = []  // interior only: t ∈ (0, 1)
    var anchorY: Double = 0.5     // shared y for both t=0 and t=1 loop endpoints
}

// Returns the full point list including loop-endpoint anchors,
// or nil to signal "use the sine wave formula".
func effectivePoints(for state: LFOState) -> [LFOPoint]? {
    if state.customPoints.isEmpty && abs(state.anchorY - 0.5) < 0.001 { return nil }
    var pts = [LFOPoint(t: 0, y: state.anchorY)]
    pts += state.customPoints.sorted { $0.t < $1.t }
    pts.append(LFOPoint(t: 1, y: state.anchorY))
    return pts
}

func evaluateCurveValue(at t: Double, state: LFOState) -> Double {
    guard let pts = effectivePoints(for: state) else {
        return 0.5 + 0.5 * sin(t * 2.0 * .pi)
    }
    return evaluateSortedPoints(at: t, pts: pts)
}

private func evaluateSortedPoints(at t: Double, pts: [LFOPoint]) -> Double {
    if t <= pts.first!.t { return pts.first!.y }
    if t >= pts.last!.t  { return pts.last!.y }
    for i in 0..<pts.count - 1 {
        let p0 = pts[i], p1 = pts[i + 1]
        guard t >= p0.t && t < p1.t else { continue }
        let lt = (p1.t - p0.t) > 0 ? (t - p0.t) / (p1.t - p0.t) : 0.0
        let y0 = i > 0 ? pts[i-1].y : p0.y
        let y3 = i < pts.count - 2 ? pts[i+2].y : p1.y
        return catmullRomSpline(lt, y0, p0.y, p1.y, y3).clamped(to: 0...1)
    }
    return 0.5
}

private func catmullRomSpline(_ t: Double, _ p0: Double, _ p1: Double,
                               _ p2: Double, _ p3: Double) -> Double {
    0.5 * ((2*p1) + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t*t + (-p0+3*p1-3*p2+p3)*t*t*t)
}

class LFOManager: ObservableObject {
    let bandCount: Int
    @Published var states: [LFOState]
    @Published var effectiveGains: [Float]

    var baseGains: [Float] = [] {
        didSet {
            // Keep effectiveGains in sync for non-LFO bands when not playing
            if timer == nil {
                effectiveGains = baseGains
            }
        }
    }
    var onEffectiveGainsUpdated: (([Float]) -> Void)?

    private var playStartTime: Date? = nil
    private var timer: Timer?
    private var slewedGains: [Float]

    // Full 0→1 range takes ≥ 5 seconds at 30 Hz
    private let maxSlewPerTick: Float = 1.0 / (5.0 * 30.0)

    init(bandCount: Int) {
        self.bandCount = bandCount
        self.states = Array(repeating: LFOState(), count: bandCount)
        self.slewedGains = Array(repeating: 0.5, count: bandCount)
        self.effectiveGains = Array(repeating: 0.5, count: bandCount)
    }

    func setPlaying(_ playing: Bool, currentGains: [Float]) {
        if playing {
            if playStartTime == nil {
                playStartTime = Date()
                slewedGains = currentGains
            }
            startTimer()
        } else {
            stopTimer()
            playStartTime = nil
            effectiveGains = currentGains
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
            if states[i].isEnabled {
                let t = (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0)
                let target = Float(evaluateCurveValue(at: t, state: states[i]))
                let delta = target - slewedGains[i]
                slewedGains[i] += max(-maxSlewPerTick, min(maxSlewPerTick, delta))
                effective[i] = slewedGains[i]
            } else {
                // Keep slewed value in sync with base so transitions are instant when re-enabled
                slewedGains[i] = baseGains[i]
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.effectiveGains = effective
        }
        onEffectiveGainsUpdated?(effective)
    }

    func currentPhase(forBand i: Int) -> Double {
        guard let startTime = playStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return (elapsed / states[i].period).truncatingRemainder(dividingBy: 1.0)
    }
}
