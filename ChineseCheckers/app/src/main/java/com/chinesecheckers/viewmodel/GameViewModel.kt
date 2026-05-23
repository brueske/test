package com.chinesecheckers.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.data.repository.AppRepository
import com.chinesecheckers.game.BoardPos
import com.chinesecheckers.game.GameLogic
import com.chinesecheckers.game.GameState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class GameViewModel(
    private val repository: AppRepository,
    val player1: Profile,
    val player2: Profile
) : ViewModel() {

    private val _state = MutableStateFlow(GameState.initial())
    val state: StateFlow<GameState> = _state.asStateFlow()

    private val _resultSaved = MutableStateFlow(false)
    val resultSaved: StateFlow<Boolean> = _resultSaved.asStateFlow()

    fun onTap(pos: BoardPos) {
        val next = GameLogic.handleTap(_state.value, pos)
        _state.value = next

        if (next.winner != null && !_resultSaved.value) {
            _resultSaved.value = true
            viewModelScope.launch {
                val winnerId = if (next.winner == 1) player1.id else player2.id
                repository.recordResult(player1.id, player2.id, winnerId)
            }
        }
    }

    fun endJump() {
        _state.value = GameLogic.endJump(_state.value)
    }

    fun newGame() {
        _state.value = GameState.initial()
        _resultSaved.value = false
    }

    class Factory(
        private val repository: AppRepository,
        private val player1: Profile,
        private val player2: Profile
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            GameViewModel(repository, player1, player2) as T
    }
}
