package com.chinesecheckers.game

import kotlin.math.abs
import kotlin.math.sqrt

data class BoardPos(val row: Int, val col: Int)

object Board {
    val allPositions: Set<BoardPos> by lazy { buildPositions() }

    val player1Home: Set<BoardPos> by lazy {
        allPositions.filter { it.row in 0..3 }.toSet()
    }

    val player2Home: Set<BoardPos> by lazy {
        allPositions.filter { it.row in 13..16 }.toSet()
    }

    private fun buildPositions(): Set<BoardPos> {
        val positions = mutableSetOf<BoardPos>()

        // Top triangle rows 0–3 (Player 1 home)
        // Row r: (r+1) holes starting at col (12 - r), step 2
        for (row in 0..3) {
            val count = row + 1
            val startCol = 12 - row
            for (i in 0 until count) {
                positions += BoardPos(row, startCol + i * 2)
            }
        }

        // Middle section rows 4–12
        // Row r: (9 + |r-8|) holes starting at col (4 - |r-8|), step 2
        for (row in 4..12) {
            val dist = abs(row - 8)
            val count = 9 + dist
            val startCol = 4 - dist
            for (i in 0 until count) {
                positions += BoardPos(row, startCol + i * 2)
            }
        }

        // Bottom triangle rows 13–16 (Player 2 home)
        // Row r: (17-r) holes starting at col (r-4), step 2
        for (row in 13..16) {
            val count = 17 - row
            val startCol = row - 4
            for (i in 0 until count) {
                positions += BoardPos(row, startCol + i * 2)
            }
        }

        return positions
    }

    fun getNeighbors(pos: BoardPos): List<BoardPos> {
        val candidates = listOf(
            BoardPos(pos.row, pos.col - 2),
            BoardPos(pos.row, pos.col + 2),
            BoardPos(pos.row - 1, pos.col - 1),
            BoardPos(pos.row - 1, pos.col + 1),
            BoardPos(pos.row + 1, pos.col - 1),
            BoardPos(pos.row + 1, pos.col + 1)
        )
        return candidates.filter { it in allPositions }
    }

    fun jumpTarget(from: BoardPos, over: BoardPos): BoardPos =
        BoardPos(2 * over.row - from.row, 2 * over.col - from.col)

    // Maps doubled-coordinate position to screen pixel offset
    fun toScreen(pos: BoardPos, cellSize: Float, originX: Float, originY: Float): Pair<Float, Float> {
        val x = originX + pos.col * cellSize * 0.5f
        val y = originY + pos.row * cellSize * sqrt(3.0).toFloat() * 0.5f
        return x to y
    }
}
