import SwiftUI

struct FrequencySliderView: View {
    @Binding var gains: [Float]
    let labels: [String]
    @ObservedObject var lfoManager: LFOManager
    let isPlaying: Bool
    var onLFOLongPress: ((Int) -> Void)?

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<gains.count, id: \.self) { i in
                    sliderColumn(index: i, totalHeight: geo.size.height)
                }
            }
        }
    }

    private func sliderColumn(index i: Int, totalHeight: CGFloat) -> some View {
        let iconH: CGFloat = 22
        let iconGap: CGFloat = 6
        let labelH: CGFloat = 20
        let trackH = max(16, totalHeight - iconH - iconGap - labelH)
        let thumbY = CGFloat(1.0 - gains[i]) * trackH

        return VStack(spacing: 0) {
            // LFO icon — tap to toggle, long press to open editor
            LFOIconView(
                state: $lfoManager.states[i],
                onLongPress: { onLFOLongPress?(i) }
            )
            .frame(height: iconH)

            Color.clear.frame(height: iconGap)

            // Slider track + thumb
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: trackH)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1, height: max(0, thumbY))
                    .frame(maxWidth: .infinity)

                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .frame(maxWidth: .infinity)
                    .offset(y: thumbY - 7)
            }
            .frame(height: trackH)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let normalized = Float(1.0 - (value.location.y / trackH))
                        gains[i] = min(1.0, max(0.0, normalized))
                    }
            )

            // Band label
            Text(labels[i])
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .frame(height: labelH)
        }
        .frame(maxWidth: .infinity)
    }
}
