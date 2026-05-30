import Foundation

enum GameLogic {

    static func handleTap(_ state: GameState, pos: BoardPos) -> GameState {
        guard state.winner == nil else { return state }
        // Once hasMoved and not in a jump chain, only Confirm/Undo work
        if state.hasMoved && !state.isJumping { return state }

        if state.isJumping {
            if state.validMoves.contains(pos) { return execute(state, from: state.jumpPos!, to: pos) }
            return state
        }

        let pieceHere = state.pieces[pos]
        if let p = pieceHere, p == state.currentPlayer { return selectPiece(state, pos: pos) }
        if state.selectedPos != nil && state.validMoves.contains(pos) { return execute(state, from: state.selectedPos!, to: pos) }
        if state.selectedPos != nil {
            var s = state; s.selectedPos = nil; s.validMoves = []; return s
        }
        return state
    }

    static func confirmTurn(_ state: GameState) -> GameState {
        var s = state
        s.currentPlayer = state.currentPlayer == 1 ? 2 : 1
        s.selectedPos = nil; s.validMoves = []
        s.isJumping = false; s.jumpPos = nil; s.jumpVisited = []
        s.hasMoved = false
        s.moveCount += 1
        return s
    }

    // MARK: - Private

    private static func selectPiece(_ state: GameState, pos: BoardPos) -> GameState {
        var s = state
        s.selectedPos = pos
        s.validMoves = validMoves(from: pos, pieces: state.pieces, visited: [pos])
        return s
    }

    private static func execute(_ state: GameState, from: BoardPos, to: BoardPos) -> GameState {
        var pieces = state.pieces
        let player = pieces.removeValue(forKey: from)!
        pieces[to] = player

        let winner = checkWinner(pieces: pieces)
        let jumped = isJump(from: from, to: to)

        var s = state
        s.pieces = pieces
        s.hasMoved = true
        s.winner = winner

        if jumped && winner == nil {
            let visited = state.jumpVisited.union([from, to])
            let more = jumpMoves(from: to, pieces: pieces, visited: visited)
            if !more.isEmpty {
                s.isJumping = true; s.jumpPos = to
                s.jumpVisited = visited; s.validMoves = more; s.selectedPos = to
                return s
            }
        }

        s.isJumping = false; s.jumpPos = nil; s.jumpVisited = []
        s.validMoves = []; s.selectedPos = to
        return s
    }

    private static func validMoves(from: BoardPos, pieces: [BoardPos: Int], visited: Set<BoardPos>) -> Set<BoardPos> {
        var moves = Set<BoardPos>()
        for n in Board.neighbors(of: from) where pieces[n] == nil { moves.insert(n) }
        moves.formUnion(jumpMoves(from: from, pieces: pieces, visited: visited))
        return moves
    }

    private static func jumpMoves(from: BoardPos, pieces: [BoardPos: Int], visited: Set<BoardPos>) -> Set<BoardPos> {
        var moves = Set<BoardPos>()
        let directions: [(Int, Int)] = [(0, 2), (0, -2), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        for (dr, dc) in directions {
            var k = 1
            while true {
                let scanned = BoardPos(row: from.row + k * dr, col: from.col + k * dc)
                guard Board.allPositions.contains(scanned) else { break }
                if pieces[scanned] != nil {
                    let target = BoardPos(row: from.row + 2 * k * dr, col: from.col + 2 * k * dc)
                    if Board.allPositions.contains(target) && pieces[target] == nil && !visited.contains(target) {
                        moves.insert(target)
                        moves.formUnion(jumpMoves(from: target, pieces: pieces, visited: visited.union([target])))
                    }
                    break
                }
                k += 1
            }
        }
        return moves
    }

    private static func isJump(from: BoardPos, to: BoardPos) -> Bool {
        abs(from.row - to.row) > 1 || abs(from.col - to.col) > 2
    }

    private static func checkWinner(pieces: [BoardPos: Int]) -> Int? {
        let p1 = pieces.filter { $0.value == 1 }.keys
        let p2 = pieces.filter { $0.value == 2 }.keys
        if !p1.isEmpty && p1.allSatisfy({ Board.player2Home.contains($0) }) { return 1 }
        if !p2.isEmpty && p2.allSatisfy({ Board.player1Home.contains($0) }) { return 2 }
        return nil
    }
}
