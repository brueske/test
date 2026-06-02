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

    // Wiggle mode state
    @State private var isWiggling = false
    @State private var wigglePhase: Bool = false
    @State private var wiggleTimer: Timer? = nil
    @State private var draggingProfileID: UUID? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    if isWiggling { stopWiggling() }
                }

            GeometryReader { geo in
                VStack(spacing: 0) {
                    topBar
                        .frame(height: 56)

                    Spacer()

                    playButton
                        .frame(height: 100)

                    pinnedProfilesGrid
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
                lfoManager: lfoManager,
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

    // MARK: - Pinned profiles 4×2 grid

    private var pinnedProfilesGrid: some View {
        let pinned = profileManager.pinnedProfiles
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<8, id: \.self) { slot in
                if slot < pinned.count {
                    let profile = pinned[slot]
                    let isActive = activeProfileID == profile.id
                    profileChip(profile: profile, isActive: isActive)
                } else {
                    emptyChip
                }
            }
        }
        .padding(.horizontal, 28)
        .onTapGesture {
            if isWiggling { stopWiggling() }
        }
    }

    private func profileChip(profile: NoiseProfile, isActive: Bool) -> some View {
        let wiggleAngle: Double = isWiggling
            ? (wigglePhase ? 2.0 : -2.0)
            : 0.0

        return Button(action: {
            if isWiggling {
                stopWiggling()
                return
            }
            audioEngine.bandGains = profile.bandGains
            if let saved = profile.lfoStates, saved.count == lfoManager.bandCount {
                lfoManager.states = saved
            }
            activeProfileID = profile.id
        }) {
            Text(profile.name.uppercased())
                .font(.system(size: 10, weight: .light, design: .monospaced))
                .tracking(1.5)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(isActive ? .white : .white.opacity(0.4))
                .padding(.horizontal, 8)
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
        .rotationEffect(.degrees(wiggleAngle))
        .animation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true), value: wigglePhase)
        .onLongPressGesture(minimumDuration: 0.4) {
            startWiggling()
        }
    }

    private var emptyChip: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            .frame(height: 34)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Wiggle

    private func startWiggling() {
        isWiggling = true
        wigglePhase = false
        wiggleTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            wigglePhase.toggle()
        }
    }

    private func stopWiggling() {
        isWiggling = false
        wiggleTimer?.invalidate()
        wiggleTimer = nil
        wigglePhase = false
    }
}
