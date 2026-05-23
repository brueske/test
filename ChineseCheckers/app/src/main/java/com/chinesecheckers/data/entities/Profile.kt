package com.chinesecheckers.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "profiles")
data class Profile(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val avatarType: Int = 0,   // index into AvatarType enum (0–7)
    val wins: Int = 0
)
