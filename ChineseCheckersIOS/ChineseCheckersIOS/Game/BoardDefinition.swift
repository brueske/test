import Foundation
import CoreGraphics

// Doubled hex coordinates — row + col always same parity.
struct BoardPos: Hashable, Equatable, Codable {
    let row: Int
    let col: Int
}

enum Board {
    static let allPositions: Set<BoardPos> = buildPositions()
    static let player1Home:  Set<BoardPos> = Set(allPositions.filter { $0.row <= 3  })
    static let player2Home:  Set<BoardPos> = Set(allPositions.filter { $0.row >= 13 })

    private static func buildPositions() -> Set<BoardPos> {
        var set = Set<BoardPos>()
        // Top triangle rows 0–3
        for row in 0...3 {
            let start = 12 - row
            for i in 0...row { set.insert(.init(row: row, col: start + i * 2)) }
        }
        // Middle rows 4–12
        for row in 4...12 {
            let dist = abs(row - 8)
            let count = 9 + dist
            let start = 4 - dist
            for i in 0..<count { set.insert(.init(row: row, col: start + i * 2)) }
        }
        // Bottom triangle rows 13–16
        for row in 13...16 {
            let count = 17 - row
            let start = row - 4
            for i in 0..<count { set.insert(.init(row: row, col: start + i * 2)) }
        }
        return set
    }

    static func neighbors(of pos: BoardPos) -> [BoardPos] {
        [
            .init(row: pos.row,     col: pos.col - 2),
            .init(row: pos.row,     col: pos.col + 2),
            .init(row: pos.row - 1, col: pos.col - 1),
            .init(row: pos.row - 1, col: pos.col + 1),
            .init(row: pos.row + 1, col: pos.col - 1),
            .init(row: pos.row + 1, col: pos.col + 1),
        ].filter { allPositions.contains($0) }
    }

    static func jumpTarget(from: BoardPos, over: BoardPos) -> BoardPos {
        .init(row: 2 * over.row - from.row, col: 2 * over.col - from.col)
    }

    // Screen coordinates using doubled-coord spacing
    static func screenPoint(pos: BoardPos, cellSize: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(pos.col) * cellSize * 0.5,
            y: origin.y + CGFloat(pos.row) * cellSize * sqrt(3.0) / 2.0
        )
    }
}
