import SwiftUI

struct LFOIconView: View {
    @Binding var state: LFOState
    var onLongPress: () -> Void

    @State private var longPressTriggered = false

    var body: some View {
        Canvas { context, size in
            // 1.5-cycle sine wave
            var wave = Path()
            let steps = 60
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * size.width
                let y = size.height / 2 - (size.height * 0.42) * sin(t * .pi * 3.0)
                if i == 0 { wave.move(to: CGPoint(x: x, y: y)) }
                else { wave.addLine(to: CGPoint(x: x, y: y)) }
            }
            let waveOpacity: Double = state.isEnabled ? 0.85 : 0.22
            context.stroke(wave, with: .color(.white.opacity(waveOpacity)), lineWidth: 1.0)

            // "/" slash overlay when disabled
            if !state.isEnabled {
                var slash = Path()
                slash.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.95))
                slash.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.05))
                context.stroke(slash, with: .color(.white.opacity(0.5)), lineWidth: 1.0)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 12) {
            longPressTriggered = true
            onLongPress()
        } onPressingChanged: { isPressing in
            if !isPressing && !longPressTriggered {
                state.isEnabled.toggle()
            }
            if !isPressing { longPressTriggered = false }
        }
    }
}
