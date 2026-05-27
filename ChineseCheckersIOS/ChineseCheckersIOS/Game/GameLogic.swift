import Foundation

enum GameLogic {

    static func handleTap(_ state: GameState, pos: BoardPos) -> GameState {
        guard state.winner == nil else { return state }

        if state.isJumping {
            if pos == state.jumpPos          { return endJump(state) }
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

    static func endJump(_ state: GameState) -> GameState {
        var s = state
        s.currentPlayer = state.currentPlayer == 1 ? 2 : 1
        s.selectedPos = nil; s.validMoves = []; s.isJumping = false; s.jumpPos = nil; s.jumpVisited = []
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

        if isJump(from: from, to: to) {
            let visited = state.jumpVisited.union([from, to])
            let more = jumpMoves(from: to, pieces: pieces, visited: visited)
            if !more.isEmpty {
                var s = state
                s.pieces = pieces; s.isJumping = true; s.jumpPos = to
                s.jumpVisited = visited; s.validMoves = more; s.selectedPos = to
                return s
            }
        }

        let winner = checkWinner(pieces: pieces)
        var s = state
        s.pieces = pieces
        s.currentPlayer = state.currentPlayer == 1 ? 2 : 1
        s.selectedPos = nil; s.validMoves = []; s.isJumping = false; s.jumpPos = nil; s.jumpVisited = []
        s.winner = winner
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
        for n in Board.neighbors(of: from) where pieces[n] != nil {
            let t = Board.jumpTarget(from: from, over: n)
            guard Board.allPositions.contains(t), pieces[t] == nil, !visited.contains(t) else { continue }
            moves.insert(t)
            moves.formUnion(jumpMoves(from: t, pieces: pieces, visited: visited.union([t])))
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
