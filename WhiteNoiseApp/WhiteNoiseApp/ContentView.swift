import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var lfoManager = LFOManager(bandCount: 8)

    @State private var showProfiles = false
    @State private var playButtonScale: CGFloat = 1.0
    @State private var activeProfileID: UUID? = nil
    @State private var showLFOEditor = false
    @State private var lfoEditorBandIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    topBar
                        .frame(height: 56)

                    Spacer()

                    playButton
                        .frame(height: 100)

                    quickProfilesRow
                        .padding(.top, 28)
                        .padding(.bottom, 4)

                    Spacer()

                    FrequencySliderView(
                        gains: $audioEngine.bandGains,
                        labels: audioEngine.bandLabels,
                        lfoManager: lfoManager,
                        isPlaying: audioEngine.isPlaying,
                        onLFOLongPress: { i in
                            lfoEditorBandIndex = i
                            showLFOEditor = true
                        }
                    )
                    .frame(height: geo.size.height * 0.30)
                    .padding(.horizontal, 16)

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
        .onAppear {
            lfoManager.baseGains = audioEngine.bandGains
            lfoManager.onEffectiveGainsUpdated = { [weak audioEngine] gains in
                audioEngine?.updateEQWithGains(gains)
            }
        }
        .onChange(of: audioEngine.bandGains) { newGains in
            lfoManager.baseGains = newGains
        }
        .onChange(of: audioEngine.isPlaying) { playing in
            lfoManager.setPlaying(playing, currentGains: audioEngine.bandGains)
        }
        .sheet(isPresented: $showProfiles) {
            ProfileSheetView(
                profileManager: profileManager,
                audioEngine: audioEngine,
                activeProfileID: $activeProfileID
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(.black)
        }
        .sheet(isPresented: $showLFOEditor) {
            LFOEditorView(
                bandIndex: lfoEditorBandIndex,
                bandLabel: audioEngine.bandLabels[lfoEditorBandIndex],
                lfoManager: lfoManager,
                isPlaying: audioEngine.isPlaying
            )
            .presentationDetents([.large])
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
            withAnimation(.easeInOut(duration: 0.1)) { playButtonScale = 0.9 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { playButtonScale = 1.0 }
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
                    HStack(spacing: 10) {
                        Rectangle().fill(Color.white).frame(width: 2, height: 26)
                        Rectangle().fill(Color.white).frame(width: 2, height: 26)
                    }
                } else {
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

    // MARK: - Quick profile row

    private var quickProfilesRow: some View {
        let slots = Array(profileManager.profiles.prefix(4))
        return HStack(spacing: 10) {
            ForEach(slots) { profile in
                let isActive = activeProfileID == profile.id
                Button(action: {
                    audioEngine.bandGains = profile.bandGains
                    activeProfileID = profile.id
                }) {
                    Text(profile.name.uppercased())
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .tracking(1.5)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(isActive ? .white : .white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(
                                    isActive ? Color.white.opacity(0.7) : Color.white.opacity(0.18),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            if slots.count < 4 {
                ForEach(slots.count..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                        .frame(height: 34)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 28)
    }
}
