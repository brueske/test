import SwiftUI

struct LFOEditorView: View {
    let bandIndex: Int
    let bandLabel: String
    @ObservedObject var lfoManager: LFOManager
    let isPlaying: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var lastMagnification: CGFloat = 1.0
    @State private var graphSize: CGSize = .zero
    @State private var draggingIndex: Int? = nil

    private var state: LFOState { lfoManager.states[bandIndex] }
    private var points: [LFOPoint] { state.customPoints }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.1))
                    .padding(.bottom, 28)

                graphSection
                    .padding(.horizontal, 24)

                Spacer()

                hintAndReset
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                periodInfo
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                toggleButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Text("LFO")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(3)
                Text("·")
                    .foregroundColor(.white.opacity(0.2))
                    .font(.system(size: 11, weight: .ultraLight))
                Text(bandLabel.uppercased())
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(3)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Graph

    private var graphSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("1.0")
                Spacer()
                Text("0.5")
                Spacer()
                Text("0.0")
            }
            .font(.system(size: 9, weight: .light, design: .monospaced))
            .foregroundColor(.white.opacity(0.28))
            .frame(width: 26, height: 180)
            .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 0) {
                graphCanvas
                    .frame(height: 180)

                HStack {
                    Text("0")
                    Spacer()
                    Text(formatTime(state.period / 2))
                    Spacer()
                    Text(formatTime(state.period))
                }
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.28))
                .padding(.top, 6)
            }
        }
    }

    private var graphCanvas: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { _ in
            let phase: Double = (isPlaying && state.isEnabled)
                ? lfoManager.currentPhase(forBand: bandIndex)
                : -1
            let pts = points
            let dragIdx = draggingIndex

            Canvas { ctx, size in
                drawGraph(&ctx, size: size, phase: phase, points: pts)
                drawControlPoints(&ctx, size: size, points: pts, dragIdx: dragIdx)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { graphSize = geo.size }
                    .onChange(of: geo.size) { graphSize = $0 }
            }
        )
        // Pinch: apart = zoom in (shorter period), together = zoom out (longer period)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastMagnification
                    lastMagnification = value
                    let newPeriod = (state.period / Double(delta)).clamped(to: 30...1800)
                    lfoManager.states[bandIndex].period = newPeriod
                }
                .onEnded { _ in lastMagnification = 1.0 }
        )
        // Single-finger drag: add or move control points
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard graphSize.width > 0, graphSize.height > 0 else { return }
                    let t = Double(value.location.x / graphSize.width).clamped(to: 0...1)
                    let y = Double(1 - value.location.y / graphSize.height).clamped(to: 0...1)

                    if draggingIndex == nil {
                        if let nearest = nearestPointIndex(to: value.startLocation) {
                            draggingIndex = nearest
                        } else {
                            lfoManager.states[bandIndex].customPoints.append(LFOPoint(t: t, y: y))
                            draggingIndex = lfoManager.states[bandIndex].customPoints.count - 1
                        }
                    }

                    if let idx = draggingIndex {
                        lfoManager.states[bandIndex].customPoints[idx].t = t
                        lfoManager.states[bandIndex].customPoints[idx].y = y
                    }
                }
                .onEnded { _ in
                    lfoManager.states[bandIndex].customPoints.sort { $0.t < $1.t }
                    draggingIndex = nil
                }
        )
    }

    private func nearestPointIndex(to location: CGPoint) -> Int? {
        guard graphSize.width > 0, graphSize.height > 0 else { return nil }
        let threshold: CGFloat = 24
        var best: (Int, CGFloat)? = nil
        for (i, pt) in points.enumerated() {
            let px = CGFloat(pt.t) * graphSize.width
            let py = CGFloat(1 - pt.y) * graphSize.height
            let d = hypot(location.x - px, location.y - py)
            if d < threshold, best == nil || d < best!.1 {
                best = (i, d)
            }
        }
        return best?.0
    }

    // MARK: - Drawing

    private func drawGraph(_ ctx: inout GraphicsContext, size: CGSize, phase: Double, points: [LFOPoint]) {
        let rect = CGRect(origin: .zero, size: size)

        drawGridLine(&ctx, from: CGPoint(x: 0, y: rect.midY), to: CGPoint(x: rect.maxX, y: rect.midY))
        drawGridLine(&ctx, from: CGPoint(x: rect.midX, y: 0), to: CGPoint(x: rect.midX, y: rect.maxY))

        if phase >= 0 {
            ctx.fill(areaPath(rect, from: 0, to: phase, points: points), with: .color(.white.opacity(0.13)))
            ctx.stroke(wavePath(rect, from: 0, to: phase, points: points),
                       with: .color(.white.opacity(0.9)), lineWidth: 1.5)

            ctx.fill(areaPath(rect, from: phase, to: 1, points: points), with: .color(.white.opacity(0.04)))
            ctx.stroke(wavePath(rect, from: phase, to: 1, points: points),
                       with: .color(.white.opacity(0.22)), lineWidth: 1.5)

            let px = CGFloat(phase) * size.width
            var ph = Path()
            ph.move(to: CGPoint(x: px, y: 0))
            ph.addLine(to: CGPoint(x: px, y: size.height))
            ctx.stroke(ph, with: .color(.white.opacity(0.75)), lineWidth: 1.0)
        } else {
            ctx.fill(areaPath(rect, from: 0, to: 1, points: points), with: .color(.white.opacity(0.04)))
            ctx.stroke(wavePath(rect, from: 0, to: 1, points: points),
                       with: .color(.white.opacity(state.isEnabled ? 0.5 : 0.18)), lineWidth: 1.5)
        }
    }

    private func drawControlPoints(_ ctx: inout GraphicsContext, size: CGSize, points: [LFOPoint], dragIdx: Int?) {
        for (i, pt) in points.enumerated() {
            let px = CGFloat(pt.t) * size.width
            let py = CGFloat(1 - pt.y) * size.height
            let r: CGFloat = dragIdx == i ? 7 : 5
            let rect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)
            let ring = Path(ellipseIn: rect)
            let opacity: Double = dragIdx == i ? 1.0 : 0.65
            ctx.stroke(ring, with: .color(.white.opacity(opacity)), lineWidth: 1.5)
        }
    }

    private func drawGridLine(_ ctx: inout GraphicsContext, from a: CGPoint, to b: CGPoint) {
        var p = Path(); p.move(to: a); p.addLine(to: b)
        ctx.stroke(p, with: .color(.white.opacity(0.07)), lineWidth: 0.5)
    }

    private func wavePath(_ rect: CGRect, from s: Double, to e: Double, points: [LFOPoint]) -> Path {
        var path = Path()
        let range = e - s
        guard range > 0 else { return path }
        let steps = max(2, Int(120 * range))
        for i in 0...steps {
            let t = s + Double(i) / Double(steps) * range
            let x = rect.minX + CGFloat(t) * rect.width
            let y = rect.minY + CGFloat(1 - evaluateCurveValue(at: t, points: points)) * rect.height
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    private func areaPath(_ rect: CGRect, from s: Double, to e: Double, points: [LFOPoint]) -> Path {
        var path = Path()
        let range = e - s
        guard range > 0 else { return path }
        let steps = max(2, Int(120 * range))
        path.move(to: CGPoint(x: rect.minX + CGFloat(s) * rect.width, y: rect.maxY))
        for i in 0...steps {
            let t = s + Double(i) / Double(steps) * range
            let x = rect.minX + CGFloat(t) * rect.width
            let y = rect.minY + CGFloat(1 - evaluateCurveValue(at: t, points: points)) * rect.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.minX + CGFloat(e) * rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    // MARK: - Hint + Reset

    private var hintAndReset: some View {
        HStack {
            Text(points.isEmpty ? "Tap to add points · Drag to move" : "Tap to add · Drag to move · Reset to clear")
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
            Spacer()
            if !points.isEmpty {
                Button(action: {
                    lfoManager.states[bandIndex].customPoints = []
                }) {
                    Text("RESET")
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Period info

    private var periodInfo: some View {
        VStack(spacing: 5) {
            HStack {
                Text("PERIOD")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.28))
                Spacer()
                Text(formatTime(state.period))
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.65))
            }
            Text("Pinch apart to zoom in  ·  Pinch together to zoom out")
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Toggle

    private var toggleButton: some View {
        Button(action: { lfoManager.states[bandIndex].isEnabled.toggle() }) {
            HStack(spacing: 8) {
                if state.isEnabled {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .light))
                    Text("LFO ENABLED")
                } else {
                    Text("ENABLE LFO")
                }
            }
            .font(.system(size: 11, weight: .light, design: .monospaced))
            .tracking(2)
            .foregroundColor(state.isEnabled ? .white : .white.opacity(0.38))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        state.isEnabled ? Color.white.opacity(0.5) : Color.white.opacity(0.14),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 { return "\(Int(seconds.rounded()))s" }
        let m = Int(seconds / 60)
        let s = Int(seconds.truncatingRemainder(dividingBy: 60))
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}
