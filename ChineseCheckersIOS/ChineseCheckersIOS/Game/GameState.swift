import Foundation

struct GameState {
    var pieces:        [BoardPos: Int] = [:]
    var currentPlayer: Int = 1
    var selectedPos:   BoardPos?       = nil
    var validMoves:    Set<BoardPos>   = []
    var isJumping:     Bool            = false
    var jumpPos:       BoardPos?       = nil
    var jumpVisited:   Set<BoardPos>   = []
    var winner:        Int?            = nil
    var moveCount:     Int             = 0
    var hasMoved:      Bool            = false

    static func initial() -> GameState {
        var s = GameState()
        Board.player1Home.forEach { s.pieces[$0] = 1 }
        Board.player2Home.forEach { s.pieces[$0] = 2 }
        return s
    }

    // Minimal snapshot for saving: strips ephemeral selection state
    var cleanSnapshot: GameState {
        var s = GameState()
        s.pieces = pieces
        s.currentPlayer = currentPlayer
        s.moveCount = moveCount
        return s
    }
}

extension GameState: Codable {
    private struct PieceCodable: Codable { let row, col, player: Int }

    enum CodingKeys: String, CodingKey {
        case pieces, currentPlayer, selectedPos, validMoves
        case isJumping, jumpPos, jumpVisited, winner, moveCount, hasMoved
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(pieces.map { PieceCodable(row: $0.key.row, col: $0.key.col, player: $0.value) }, forKey: .pieces)
        try c.encode(currentPlayer, forKey: .currentPlayer)
        try c.encodeIfPresent(selectedPos, forKey: .selectedPos)
        try c.encode(Array(validMoves), forKey: .validMoves)
        try c.encode(isJumping, forKey: .isJumping)
        try c.encodeIfPresent(jumpPos, forKey: .jumpPos)
        try c.encode(Array(jumpVisited), forKey: .jumpVisited)
        try c.encodeIfPresent(winner, forKey: .winner)
        try c.encode(moveCount, forKey: .moveCount)
        try c.encode(hasMoved, forKey: .hasMoved)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pairs = try c.decode([PieceCodable].self, forKey: .pieces)
        pieces = Dictionary(uniqueKeysWithValues: pairs.map { (BoardPos(row: $0.row, col: $0.col), $0.player) })
        currentPlayer = try c.decode(Int.self, forKey: .currentPlayer)
        selectedPos   = try c.decodeIfPresent(BoardPos.self, forKey: .selectedPos)
        validMoves    = Set(try c.decode([BoardPos].self, forKey: .validMoves))
        isJumping     = try c.decode(Bool.self, forKey: .isJumping)
        jumpPos       = try c.decodeIfPresent(BoardPos.self, forKey: .jumpPos)
        jumpVisited   = Set(try c.decode([BoardPos].self, forKey: .jumpVisited))
        winner        = try c.decodeIfPresent(Int.self, forKey: .winner)
        moveCount     = try c.decode(Int.self, forKey: .moveCount)
        hasMoved      = try c.decode(Bool.self, forKey: .hasMoved)
    }
}
