import Foundation

struct GameState {
    var pieces:       [BoardPos: Int] = [:]  // position → player (1 or 2)
    var currentPlayer: Int = 1
    var selectedPos:  BoardPos?       = nil
    var validMoves:   Set<BoardPos>   = []
    var isJumping:    Bool            = false
    var jumpPos:      BoardPos?       = nil
    var jumpVisited:  Set<BoardPos>   = []
    var winner:       Int?            = nil

    static func initial() -> GameState {
        var s = GameState()
        Board.player1Home.forEach { s.pieces[$0] = 1 }
        Board.player2Home.forEach { s.pieces[$0] = 2 }
        return s
    }
}
