import SwiftUI

/// Top-level layout: a code panel taking the left 2/3, and a right 1/3 column
/// split into a definition box (top) and an LLM panel (bottom).
struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                CodePanelView()
                    .frame(width: geo.size.width * 2.0 / 3.0)

                Divider()

                VStack(spacing: 0) {
                    DefinitionView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Divider()
                    LLMPanelView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
