package com.chinesecheckers.data.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.chinesecheckers.data.dao.GameRecordDao
import com.chinesecheckers.data.dao.ProfileDao
import com.chinesecheckers.data.entities.GameRecord
import com.chinesecheckers.data.entities.Profile

@Database(entities = [Profile::class, GameRecord::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun profileDao(): ProfileDao
    abstract fun gameRecordDao(): GameRecordDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "chinese_checkers.db"
                ).build().also { INSTANCE = it }
            }
    }
}
