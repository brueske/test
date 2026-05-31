import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var profileManager = ProfileManager()

    @State private var showProfiles = false
    @State private var playButtonScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // ── Top bar ──────────────────────────────────────────
                    topBar
                        .frame(height: 56)

                    Spacer()

                    // ── Play/Pause button ────────────────────────────────
                    playButton
                        .frame(height: 100)

                    Spacer()

                    // ── Frequency sliders ────────────────────────────────
                    FrequencySliderView(
                        gains: $audioEngine.bandGains,
                        labels: audioEngine.bandLabels
                    )
                    .frame(height: geo.size.height * 0.28)
                    .padding(.horizontal, 16)

                    // ── EQ visualizer ────────────────────────────────────
                    EQVisualizerView(
                        levels: audioEngine.levels,
                        bandLabels: audioEngine.bandLabels
                    )
                    .frame(height: geo.size.height * 0.14)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfiles) {
            ProfileSheetView(profileManager: profileManager, audioEngine: audioEngine)
                .presentationDetents([.medium, .large])
                .presentationBackground(.black)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { showProfiles = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 13, weight: .ultraLight))
                    Text("PROFILES")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .tracking(3)
                }
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - Play button

    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                playButtonScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    playButtonScale = 1.0
                }
                audioEngine.togglePlayback()
            }
        }) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    .frame(width: 88, height: 88)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: 100, height: 100)

                if audioEngine.isPlaying {
                    // Pause icon — two thin vertical bars
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 26)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 26)
                    }
                } else {
                    // Play icon — thin triangle
                    Image(systemName: "play.fill")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundColor(.white)
                        .offset(x: 3)
                }
            }
        }
        .scaleEffect(playButtonScale)
        .buttonStyle(.plain)
    }
}
