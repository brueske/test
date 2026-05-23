package com.chinesecheckers.game

import kotlin.math.abs

object GameLogic {

    fun handleTap(state: GameState, pos: BoardPos): GameState {
        if (state.winner != null) return state

        val pieceAtPos = state.pieces[pos]

        return when {
            // Mid-jump: tapping current piece position ends the jump chain
            state.isJumping && pos == state.jumpPos -> endJump(state)

            // Mid-jump: only valid jump continuations accepted
            state.isJumping && pos in state.validMoves -> executeMove(state, state.jumpPos!!, pos)

            // Mid-jump: ignore everything else
            state.isJumping -> state

            // Select or reselect own piece
            pieceAtPos == state.currentPlayer -> selectPiece(state, pos)

            // Move selected piece to valid destination
            state.selectedPos != null && pos in state.validMoves -> executeMove(state, state.selectedPos, pos)

            // Deselect by tapping elsewhere
            state.selectedPos != null -> state.copy(selectedPos = null, validMoves = emptySet())

            else -> state
        }
    }

    fun endJump(state: GameState): GameState {
        if (!state.isJumping) return state
        val next = if (state.currentPlayer == 1) 2 else 1
        return state.copy(
            currentPlayer = next,
            selectedPos = null,
            validMoves = emptySet(),
            isJumping = false,
            jumpPos = null,
            jumpVisited = emptySet()
        )
    }

    private fun selectPiece(state: GameState, pos: BoardPos): GameState {
        val moves = computeValidMoves(pos, state.pieces, emptySet(), isTurnStart = true)
        return state.copy(selectedPos = pos, validMoves = moves)
    }

    private fun executeMove(state: GameState, from: BoardPos, to: BoardPos): GameState {
        val newPieces = state.pieces.toMutableMap()
        val player = newPieces.remove(from)!!
        newPieces[to] = player

        val jumped = isJump(from, to)

        if (jumped) {
            val visited = state.jumpVisited + from + to
            val moreJumps = computeJumpMoves(to, newPieces, visited)
            if (moreJumps.isNotEmpty()) {
                return state.copy(
                    pieces = newPieces,
                    isJumping = true,
                    jumpPos = to,
                    jumpVisited = visited,
                    validMoves = moreJumps,
                    selectedPos = to
                )
            }
        }

        val winner = checkWinner(newPieces)
        val next = if (state.currentPlayer == 1) 2 else 1
        return state.copy(
            pieces = newPieces,
            currentPlayer = next,
            selectedPos = null,
            validMoves = emptySet(),
            isJumping = false,
            jumpPos = null,
            jumpVisited = emptySet(),
            winner = winner
        )
    }

    private fun computeValidMoves(
        from: BoardPos,
        pieces: Map<BoardPos, Int>,
        visited: Set<BoardPos>,
        isTurnStart: Boolean
    ): Set<BoardPos> {
        val moves = mutableSetOf<BoardPos>()

        if (isTurnStart) {
            // Single-step moves (only at start of turn)
            for (n in Board.getNeighbors(from)) {
                if (n !in pieces) moves += n
            }
        }

        // Jump moves (recursive)
        moves += computeJumpMoves(from, pieces, visited + from)
        return moves
    }

    private fun computeJumpMoves(
        from: BoardPos,
        pieces: Map<BoardPos, Int>,
        visited: Set<BoardPos>
    ): Set<BoardPos> {
        val moves = mutableSetOf<BoardPos>()
        for (n in Board.getNeighbors(from)) {
            if (n in pieces) {
                val target = Board.jumpTarget(from, n)
                if (target in Board.allPositions && target !in pieces && target !in visited) {
                    moves += target
                    moves += computeJumpMoves(target, pieces, visited + target)
                }
            }
        }
        return moves
    }

    private fun isJump(from: BoardPos, to: BoardPos): Boolean =
        abs(from.row - to.row) > 1 || abs(from.col - to.col) > 2

    private fun checkWinner(pieces: Map<BoardPos, Int>): Int? {
        val p1 = pieces.filter { it.value == 1 }.keys
        val p2 = pieces.filter { it.value == 2 }.keys
        if (p1.isNotEmpty() && p1.all { it in Board.player2Home }) return 1
        if (p2.isNotEmpty() && p2.all { it in Board.player1Home }) return 2
        return null
    }
}
