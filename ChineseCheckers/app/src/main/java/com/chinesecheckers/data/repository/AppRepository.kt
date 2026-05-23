package com.chinesecheckers.data.repository

import com.chinesecheckers.data.dao.GameRecordDao
import com.chinesecheckers.data.dao.ProfileDao
import com.chinesecheckers.data.entities.GameRecord
import com.chinesecheckers.data.entities.Profile
import kotlinx.coroutines.flow.Flow

class AppRepository(
    private val profileDao: ProfileDao,
    private val gameRecordDao: GameRecordDao
) {
    val allProfiles: Flow<List<Profile>> = profileDao.getAllProfiles()

    suspend fun insertProfile(profile: Profile): Long = profileDao.insert(profile)

    suspend fun updateProfile(profile: Profile) = profileDao.update(profile)

    suspend fun deleteProfile(profile: Profile) = profileDao.delete(profile)

    suspend fun getProfileById(id: Long): Profile? = profileDao.getById(id)

    suspend fun recordResult(player1Id: Long, player2Id: Long, winnerId: Long) {
        profileDao.incrementWins(winnerId)
        gameRecordDao.insert(
            GameRecord(
                player1ProfileId = player1Id,
                player2ProfileId = player2Id,
                winnerProfileId = winnerId
            )
        )
    }
}
