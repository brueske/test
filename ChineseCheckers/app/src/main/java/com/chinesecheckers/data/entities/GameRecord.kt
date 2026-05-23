package com.chinesecheckers.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "game_records")
data class GameRecord(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val player1ProfileId: Long,
    val player2ProfileId: Long,
    val winnerProfileId: Long,
    val timestamp: Long = System.currentTimeMillis()
)
