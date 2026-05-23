package com.chinesecheckers

import android.app.Application
import com.chinesecheckers.data.database.AppDatabase
import com.chinesecheckers.data.repository.AppRepository

class ChineseCheckersApp : Application() {
    val database by lazy { AppDatabase.getDatabase(this) }
    val repository by lazy {
        AppRepository(database.profileDao(), database.gameRecordDao())
    }
}
