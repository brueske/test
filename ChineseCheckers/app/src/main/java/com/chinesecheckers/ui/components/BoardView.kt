package com.chinesecheckers.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import com.chinesecheckers.game.Board
import com.chinesecheckers.game.BoardPos
import com.chinesecheckers.game.GameState
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.MidGray
import com.chinesecheckers.ui.theme.White
import kotlin.math.sqrt

// Holds the screen-space layout so tap hit-testing can reuse it without recomputing
private data class Layout(val cellSize: Float, val originX: Float, val originY: Float) {
    fun toScreen(pos: BoardPos): Offset {
        val x = originX + pos.col * cellSize * 0.5f
        val y = originY + pos.row * cellSize * sqrt(3f) * 0.5f
        return Offset(x, y)
    }

    fun nearest(tap: Offset, threshold: Float): BoardPos? {
        var best: BoardPos? = null
        var bestD = threshold
        for (pos in Board.allPositions) {
            val d = (toScreen(pos) - tap).getDistance()
            if (d < bestD) { bestD = d; best = pos }
        }
        return best
    }
}

@Composable
fun BoardView(
    state: GameState,
    onTap: (BoardPos) -> Unit,
    modifier: Modifier = Modifier
) {
    var layout by remember { mutableStateOf<Layout?>(null) }

    Canvas(
        modifier = modifier.pointerInput(Unit) {
            detectTapGestures { offset ->
                layout?.nearest(offset, layout!!.cellSize * 0.65f)?.let { onTap(it) }
            }
        }
    ) {
        // Fit the board (24 doubled-cols wide, 16 rows tall) inside the canvas
        val cellW = size.width / 13f
        val cellH = size.height / 15f
        val cell = minOf(cellW, cellH)

        val boardPixW = 12f * cell
        val boardPixH = 16f * cell * sqrt(3f) * 0.5f
        val ox = (size.width - boardPixW) * 0.5f
        val oy = (size.height - boardPixH) * 0.5f

        val l = Layout(cell, ox, oy)
        layout = l

        val holeR = cell * 0.18f
        val pieceR = cell * 0.36f
        val strokeW = cell * 0.06f

        drawBoardBackground(state, l, holeR, strokeW)
        drawEdgeLines(l, strokeW)
        drawHoles(state, l, holeR, strokeW)
        drawPieces(state, l, pieceR, strokeW)
    }
}

// Shaded triangles for home areas
private fun DrawScope.drawBoardBackground(state: GameState, l: Layout, holeR: Float, strokeW: Float) {
    // Player 1 home: tip (0,12), bottom-left (3,9), bottom-right (3,15)
    drawHomeTriangle(l, BoardPos(0, 12), BoardPos(3, 9), BoardPos(3, 15), LightGray)
    // Player 2 home: top-left (13,9), top-right (13,15), tip (16,12)
    drawHomeTriangle(l, BoardPos(13, 9), BoardPos(13, 15), BoardPos(16, 12), LightGray)
}

private fun DrawScope.drawHomeTriangle(
    l: Layout, a: BoardPos, b: BoardPos, c: BoardPos, color: Color
) {
    val sa = l.toScreen(a); val sb = l.toScreen(b); val sc = l.toScreen(c)
    val path = Path().apply {
        moveTo(sa.x, sa.y)
        lineTo(sb.x, sb.y)
        lineTo(sc.x, sc.y)
        close()
    }
    drawPath(path, color)
}

private fun DrawScope.drawEdgeLines(l: Layout, strokeW: Float) {
    val paint = Stroke(width = strokeW * 0.5f, cap = StrokeCap.Round)
    for (pos in Board.allPositions) {
        val src = l.toScreen(pos)
        for (n in Board.getNeighbors(pos)) {
            // Draw each edge once (only when neighbour is "after" pos to avoid duplicates)
            if (n.row > pos.row || (n.row == pos.row && n.col > pos.col)) {
                val dst = l.toScreen(n)
                drawLine(MidGray, src, dst, strokeW * 0.4f)
            }
        }
    }
}

private fun DrawScope.drawHoles(state: GameState, l: Layout, holeR: Float, strokeW: Float) {
    for (pos in Board.allPositions) {
        if (pos in state.pieces) continue
        val s = l.toScreen(pos)

        val isValidMove = pos in state.validMoves
        if (isValidMove) {
            // Highlight valid destinations with a filled circle and dot
            drawCircle(LightGray, holeR * 1.6f, s)
            drawCircle(Black, holeR * 1.6f, s, style = Stroke(strokeW))
            drawCircle(Black, holeR * 0.5f, s)
        } else {
            drawCircle(White, holeR, s)
            drawCircle(Black, holeR, s, style = Stroke(strokeW * 0.8f))
        }
    }
}

private fun DrawScope.drawPieces(state: GameState, l: Layout, pieceR: Float, strokeW: Float) {
    for ((pos, player) in state.pieces) {
        val s = l.toScreen(pos)
        val isSelected = (pos == state.selectedPos || pos == state.jumpPos)

        if (player == 1) {
            // Player 1: solid black
            drawCircle(Black, pieceR, s)
            if (isSelected) {
                drawCircle(White, pieceR * 0.45f, s)
                drawCircle(Black, pieceR * 0.2f, s)
            }
        } else {
            // Player 2: white with thick black border
            drawCircle(White, pieceR, s)
            drawCircle(Black, pieceR, s, style = Stroke(strokeW * 1.8f))
            if (isSelected) {
                // Fill the inside border with a dotted ring to indicate selection
                drawCircle(Black, pieceR * 0.55f, s, style = Stroke(strokeW * 0.8f))
            }
        }

        // Emphasise selection with outer glow ring
        if (isSelected) {
            drawCircle(Black, pieceR * 1.25f, s, style = Stroke(strokeW))
        }
    }
}
