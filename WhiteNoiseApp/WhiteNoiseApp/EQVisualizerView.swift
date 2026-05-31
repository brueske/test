import SwiftUI

struct EQVisualizerView: View {
    let levels: [Float]
    let bandLabels: [String]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<levels.count, id: \.self) { i in
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.85))
                                .frame(height: max(2, CGFloat(levels[i]) * geo.size.height))
                                .animation(.linear(duration: 0.05), value: levels[i])
                        }
                    }
                    Text(bandLabels[i])
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(height: 14)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
