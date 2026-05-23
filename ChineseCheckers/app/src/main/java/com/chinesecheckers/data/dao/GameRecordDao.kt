package com.chinesecheckers.data.dao

import androidx.room.Dao
import androidx.room.Insert
import com.chinesecheckers.data.entities.GameRecord

@Dao
interface GameRecordDao {
    @Insert
    suspend fun insert(record: GameRecord)
}
