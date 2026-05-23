package com.chinesecheckers.game

data class GameState(
    val pieces: Map<BoardPos, Int>,      // position -> player number (1 or 2)
    val currentPlayer: Int = 1,
    val selectedPos: BoardPos? = null,
    val validMoves: Set<BoardPos> = emptySet(),
    val isJumping: Boolean = false,      // mid-jump-chain state
    val jumpPos: BoardPos? = null,       // current piece position during jump chain
    val jumpVisited: Set<BoardPos> = emptySet(),
    val winner: Int? = null
) {
    companion object {
        fun initial(): GameState {
            val pieces = mutableMapOf<BoardPos, Int>()
            Board.player1Home.forEach { pieces[it] = 1 }
            Board.player2Home.forEach { pieces[it] = 2 }
            return GameState(pieces = pieces)
        }
    }
}
