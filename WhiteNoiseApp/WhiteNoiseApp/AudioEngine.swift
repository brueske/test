import AVFoundation
import Accelerate

class AudioEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var mixerNode = AVAudioMixerNode()
    private var noiseNode: AVAudioSourceNode?
    private var eqNode: AVAudioUnitEQ?

    @Published var isPlaying = false
    @Published var levels: [Float] = Array(repeating: 0.0, count: 8)

    // 8 frequency bands: 20Hz, 60Hz, 120Hz, 500Hz, 1kHz, 4kHz, 8kHz, 16kHz
    let bandFrequencies: [Float] = [20, 60, 120, 500, 1000, 4000, 8000, 16000]
    let bandLabels = ["20", "60", "120", "500", "1k", "4k", "8k", "16k"]

    @Published var bandGains: [Float] = Array(repeating: 0.5, count: 8) {
        didSet { updateEQBands() }
    }

    private var levelTimer: Timer?
    private var sampleBuffer: [Float] = []
    private let bufferLock = NSLock()

    init() {
        setupAudioSession()
        setupEngine()
        observeAudioSession()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func observeAudioSession() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && isPlaying {
                try? AVAudioSession.sharedInstance().setActive(true)
                if !engine.isRunning { try? engine.start() }
            }
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard let info = note.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Restart engine after route change (e.g. Bluetooth speaker connected)
        if reason == .newDeviceAvailable || reason == .oldDeviceUnavailable {
            if isPlaying && !engine.isRunning {
                try? AVAudioSession.sharedInstance().setActive(true)
                try? engine.start()
            }
        }
    }

    private func setupEngine() {
        let numBands = bandFrequencies.count
        let eq = AVAudioUnitEQ(numberOfBands: numBands)
        self.eqNode = eq

        for (i, freq) in bandFrequencies.enumerated() {
            let band = eq.bands[i]
            band.filterType = .parametric
            band.frequency = freq
            band.bandwidth = 1.0
            band.gain = gainDB(from: bandGains[i])
            band.bypass = false
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        let srcNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frameCount = Int(frameCount)
            var samples = [Float](repeating: 0, count: frameCount)
            for i in 0..<frameCount {
                samples[i] = Float.random(in: -1...1)
            }
            self.bufferLock.lock()
            self.sampleBuffer = samples
            self.bufferLock.unlock()
            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let ptr = data.bindMemory(to: Float.self, capacity: frameCount)
                for i in 0..<frameCount { ptr[i] = samples[i] }
            }
            return noErr
        }
        self.noiseNode = srcNode

        engine.attach(srcNode)
        engine.attach(eq)
        engine.attach(mixerNode)

        engine.connect(srcNode, to: eq, format: format)
        engine.connect(eq, to: mixerNode, format: format)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: format)

        mixerNode.outputVolume = 0.5

        try? engine.start()
        engine.pause()
    }

    func togglePlayback() {
        if isPlaying {
            engine.pause()
            stopLevelTimer()
            DispatchQueue.main.async { self.isPlaying = false }
        } else {
            if !engine.isRunning {
                try? engine.start()
            }
            engine.prepare()
            try? engine.start()
            startLevelTimer()
            DispatchQueue.main.async { self.isPlaying = true }
        }
    }

    func updateEQWithGains(_ gains: [Float]) {
        guard let eq = eqNode else { return }
        for (i, gain) in gains.enumerated() where i < eq.bands.count {
            eq.bands[i].gain = gainDB(from: gain)
        }
    }

    private func updateEQBands() {
        updateEQWithGains(bandGains)
    }

    private func gainDB(from normalized: Float) -> Float {
        // normalized 0-1 -> -24dB to +12dB
        return (normalized * 36.0) - 24.0
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.computeLevels()
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
        DispatchQueue.main.async {
            self.levels = Array(repeating: 0.0, count: 8)
        }
    }

    private func computeLevels() {
        bufferLock.lock()
        let samples = sampleBuffer
        bufferLock.unlock()
        guard !samples.isEmpty else { return }

        // Split samples into 8 sub-bands by decimation simulation
        let chunkSize = max(1, samples.count / 8)
        var newLevels = [Float](repeating: 0, count: 8)

        for b in 0..<8 {
            let start = b * chunkSize
            let end = min(start + chunkSize, samples.count)
            if start >= end { continue }
            let chunk = Array(samples[start..<end])
            var rms: Float = 0
            vDSP_measqv(chunk, 1, &rms, vDSP_Length(chunk.count))
            rms = sqrt(rms)
            // Apply band gain influence
            let gainInfluence = (bandGains[b] * 1.5).clamped(to: 0...1.5)
            newLevels[b] = min(1.0, rms * gainInfluence * 4.0)
        }

        DispatchQueue.main.async {
            // Smooth levels
            for i in 0..<8 {
                let current = self.levels[i]
                let target = newLevels[i]
                self.levels[i] = current + (target - current) * 0.3
            }
        }
    }

    func setVolume(_ volume: Float) {
        mixerNode.outputVolume = volume
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
