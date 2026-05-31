import SwiftUI

struct FrequencySliderView: View {
    @Binding var gains: [Float]
    let labels: [String]

    @State private var dragStartValues: [Float] = []

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0) {
                ForEach(0..<gains.count, id: \.self) { i in
                    sliderColumn(index: i, geo: geo)
                }
            }
        }
    }

    private func sliderColumn(index i: Int, geo: GeometryProxy) -> some View {
        let colWidth = geo.size.width / CGFloat(gains.count)
        let trackHeight = geo.size.height - 24
        let thumbY = CGFloat(1.0 - gains[i]) * trackHeight

        return ZStack(alignment: .top) {
            // track line
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: trackHeight)
                .frame(maxWidth: .infinity)
                .padding(.top, 0)

            // filled portion above thumb
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 1, height: max(0, thumbY))
                .frame(maxWidth: .infinity)
                .padding(.top, 0)

            // thumb
            Circle()
                .stroke(Color.white, lineWidth: 1.5)
                .frame(width: 14, height: 14)
                .frame(maxWidth: .infinity)
                .offset(y: thumbY - 7)

            // label
            Text(labels[i])
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .offset(y: trackHeight + 6)
        }
        .frame(width: colWidth, height: geo.size.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let normalized = Float(1.0 - (value.location.y / trackHeight))
                    gains[i] = min(1.0, max(0.0, normalized))
                }
        )
    }
}
