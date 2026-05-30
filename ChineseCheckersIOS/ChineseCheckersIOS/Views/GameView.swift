import SwiftUI

struct AnimatingMove: Equatable {
    let from: BoardPos
    let to:   BoardPos
}

struct GameView: View {
    let p1Name:  String
    let p2Name:  String
    let p1Emoji: String
    let p2Emoji: String
    let onMenu:  () -> Void

    @EnvironmentObject private var store: GameStore
    @State private var state:          GameState
    @State private var undoStack:      [GameState]    = []
    @State private var animatingMove:  AnimatingMove? = nil
    @State private var showWinner      = false
    @State private var winnerInfo:     (name: String, emoji: String, player: Int) = ("", "", 1)
    @State private var showSaveAlert   = false

    init(p1Name: String, p2Name: String, p1Emoji: String, p2Emoji: String,
         initialState: GameState? = nil, onMenu: @escaping () -> Void) {
        self.p1Name  = p1Name
        self.p2Name  = p2Name
        self.p1Emoji = p1Emoji
        self.p2Emoji = p2Emoji
        self.onMenu  = onMenu
        _state = State(initialValue: initialState ?? .initial())
    }

    private var currentName:  String { state.currentPlayer == 1 ? p1Name  : p2Name  }
    private var currentEmoji: String { state.currentPlayer == 1 ? p1Emoji : p2Emoji }
    private var currentColor: Color  { playerColor(state.currentPlayer) }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Turn indicator strip
                HStack {
                    Button { showSaveAlert = true } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(currentEmoji) \(currentName)'s turn")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(currentColor.animation(.none))

                // Board
                BoardView(
                    state: state,
                    animatingMove: animatingMove,
                    onTap: { handleTap($0) }
                )
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom bar
                HStack {
                    PlayerChip(name: p1Name, emoji: p1Emoji, player: 1, active: state.currentPlayer == 1)
                    Spacer()
                    if state.hasMoved || !undoStack.isEmpty {
                        HStack(spacing: 10) {
                            if !undoStack.isEmpty {
                                Button("Undo") { undoMove() }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.textMain)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Color.hole, in: Capsule())
                            }
                            Button("Confirm") { confirmTurn() }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(state.hasMoved ? Color.moveHint : Color.boardLine, in: Capsule())
                                .disabled(!state.hasMoved)
                        }
                    }
                    Spacer()
                    PlayerChip(name: p2Name, emoji: p2Emoji, player: 2, active: state.currentPlayer == 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: state.winner) { _, newWinner in
            guard let w = newWinner else { return }
            let name  = w == 1 ? p1Name  : p2Name
            let emoji = w == 1 ? p1Emoji : p2Emoji
            winnerInfo = (name: name, emoji: emoji, player: w)
            store.recordWin(for: name)
            store.recordGame(winnerName: name, winnerEmoji: emoji, moves: state.moveCount)
            store.clearSavedGame()
            showWinner = true
        }
        .fullScreenCover(isPresented: $showWinner) {
            WinnerSheet(
                winnerName:   winnerInfo.name,
                winnerEmoji:  winnerInfo.emoji,
                winnerPlayer: winnerInfo.player,
                onPlayAgain: { showWinner = false; resetGame() },
                onMenu:      { showWinner = false; onMenu() }
            )
        }
        .alert("Save & Exit", isPresented: $showSaveAlert) {
            Button("Save & Exit") { saveAndExit() }
            Button("Exit Without Saving", role: .destructive) { onMenu() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save the current game to continue later?")
        }
    }

    // MARK: - Actions

    private func handleTap(_ pos: BoardPos) {
        let prev = state
        let next = GameLogic.handleTap(state, pos: pos)
        if prev.pieces != next.pieces {
            undoStack.append(prev)
            animatingMove = detectMove(from: prev, to: next)
        }
        state = next
    }

    private func confirmTurn() {
        undoStack = []
        animatingMove = nil
        state = GameLogic.confirmTurn(state)
    }

    private func undoMove() {
        guard let prev = undoStack.popLast() else { return }
        animatingMove = nil
        state = prev
    }

    private func resetGame() {
        state = .initial()
        undoStack = []
        animatingMove = nil
    }

    private func saveAndExit() {
        store.saveGame(state: state.cleanSnapshot, p1Name: p1Name, p2Name: p2Name)
        onMenu()
    }

    private func detectMove(from old: GameState, to new: GameState) -> AnimatingMove? {
        var departed: BoardPos? = nil
        var arrived:  BoardPos? = nil
        for (pos, player) in old.pieces where new.pieces[pos] != player { departed = pos; break }
        for (pos, player) in new.pieces where old.pieces[pos] != player { arrived  = pos; break }
        guard let f = departed, let t = arrived else { return nil }
        return AnimatingMove(from: f, to: t)
    }
}

// MARK: - Player chip

private struct PlayerChip: View {
    let name:   String
    let emoji:  String
    let player: Int
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 16))
            Text(name.prefix(12))
                .font(.system(size: 13, weight: active ? .bold : .regular))
                .foregroundColor(.textMain)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(active ? playerColor(player).opacity(0.12) : Color.clear, in: Capsule())
        .overlay(Capsule().stroke(active ? playerColor(player) : Color.clear, lineWidth: 1.5))
    }
}

// MARK: - Winner sheet

private struct WinnerSheet: View {
    let winnerName:   String
    let winnerEmoji:  String
    let winnerPlayer: Int
    let onPlayAgain:  () -> Void
    let onMenu:       () -> Void

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            ConfettiView()

            VStack(spacing: 0) {
                Spacer()

                Text(winnerEmoji)
                    .font(.system(size: 80))
                    .padding(.bottom, 16)

                Text("CONGRATULATIONS")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.textMain)
                    .tracking(2)

                Text(winnerName + "!")
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(playerColor(winnerPlayer))
                    .padding(.top, 4)

                Text("wins the game!")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.textMain)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(playerColor(winnerPlayer), in: RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: onMenu) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(playerColor(winnerPlayer))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(playerColor(winnerPlayer).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    private struct Particle {
        let x:     CGFloat
        let vy:    CGFloat
        let vx:    CGFloat
        let color: Color
        let size:  CGFloat
        let delay: Double
        let round: Bool

        static func random() -> Particle {
            Particle(
                x:     CGFloat.random(in: 0.05...0.95),
                vy:    CGFloat.random(in: -750 ... -180),
                vx:    CGFloat.random(in: -55...55),
                color: [Color.p1, Color.p2, Color.moveHint, .yellow, .orange, .green].randomElement()!,
                size:  CGFloat.random(in: 7...13),
                delay: Double.random(in: 0...0.7),
                round: Bool.random()
            )
        }
    }

    @State private var particles: [Particle] = (0..<80).map { _ in Particle.random() }
    private let start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: false)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                for p in particles {
                    let age = t - p.delay
                    guard age > 0 else { continue }
                    let x = p.x * size.width  + p.vx * age
                    let y = size.height * 0.35 + p.vy * age + 0.5 * 580 * age * age
                    let alpha = max(0, 1.0 - age / 3.5)
                    guard alpha > 0 else { continue }
                    var g = ctx; g.opacity = alpha
                    let r = p.size / 2
                    let rect = CGRect(x: x - r, y: y - r, width: p.size, height: p.size)
                    g.fill(
                        p.round ? Circle().path(in: rect) : RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(p.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
