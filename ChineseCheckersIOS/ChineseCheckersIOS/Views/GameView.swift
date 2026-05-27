import SwiftUI

struct GameView: View {
    let p1Name: String
    let p2Name: String
    let onWin: (String) -> Void
    let onMenu: () -> Void

    @State private var state = GameState.initial()
    @State private var showWinner = false
    @State private var winnerInfo: (name: String, player: Int) = ("", 1)

    private var currentColor: Color { playerColor(state.currentPlayer) }
    private var currentName: String { state.currentPlayer == 1 ? p1Name : p2Name }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Turn indicator strip
                HStack {
                    Button(action: onMenu) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(currentName)'s turn")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    // Balance chevron
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(currentColor.animation(.none))

                // Board
                BoardView(state: state, onTap: { state = GameLogic.handleTap(state, pos: $0) })
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom bar
                HStack {
                    PlayerChip(name: p1Name, player: 1, active: state.currentPlayer == 1)
                    Spacer()
                    if state.isJumping {
                        Button("Done Jumping") { state = GameLogic.endJump(state) }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.moveHint, in: Capsule())
                    }
                    Spacer()
                    PlayerChip(name: p2Name, player: 2, active: state.currentPlayer == 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: state.winner) { _, newWinner in
            guard let w = newWinner else { return }
            winnerInfo = (name: w == 1 ? p1Name : p2Name, player: w)
            onWin(winnerInfo.name)
            showWinner = true
        }
        .sheet(isPresented: $showWinner) {
            WinnerSheet(
                winnerName: winnerInfo.name,
                winnerPlayer: winnerInfo.player,
                onPlayAgain: { showWinner = false; state = .initial() },
                onMenu:      { showWinner = false; onMenu() }
            )
            .presentationDetents([.medium])
            .interactiveDismissDisabled(true)
        }
    }
}

// MARK: - Sub-views

private struct PlayerChip: View {
    let name: String
    let player: Int
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(playerColor(player)).frame(width: 11, height: 11)
            Text(name.prefix(12))
                .font(.system(size: 13, weight: active ? .bold : .regular))
                .foregroundColor(.textMain)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(active ? playerColor(player).opacity(0.12) : Color.clear, in: Capsule())
        .overlay(Capsule().stroke(active ? playerColor(player) : Color.clear, lineWidth: 1.5))
    }
}

private struct WinnerSheet: View {
    let winnerName: String
    let winnerPlayer: Int
    let onPlayAgain: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(playerColor(winnerPlayer).opacity(0.15))
                    .frame(width: 88, height: 88)
                Text("🏆").font(.system(size: 42))
            }
            Spacer().frame(height: 20)
            Text(winnerName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(playerColor(winnerPlayer))
            Text("wins the game!")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.textMain)
                .padding(.top, 4)
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
                    Text("Main Menu")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.textMain)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.hole, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg.ignoresSafeArea())
    }
}
